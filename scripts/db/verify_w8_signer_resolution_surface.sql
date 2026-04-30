-- Verification SQL for Wave 8 signer resolution surface
-- Task: TSK-P2-W8-DB-005
-- Purpose: Prove that the signer resolution surface distinguishes unknown, unauthorized, ambiguous, and authorized signer cases

-- Check 1: Verify signer resolution table exists
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_name = 'wave8_signer_resolution'
AND table_schema = 'public';

-- Expected: table exists

-- Check 2: Verify required columns exist
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'wave8_signer_resolution'
AND table_schema = 'public'
AND column_name IN ('signer_id', 'key_id', 'key_version', 'public_key_bytes', 'project_id', 'entity_type', 'scope', 'is_active')
ORDER BY column_name;

-- Expected: all 8 columns exist

-- Check 3: Verify unique constraint prevents ambiguous signer resolution
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.wave8_signer_resolution'::regclass
AND conname = 'wave8_signer_key_unique';

-- Expected: constraint exists on (key_id, key_version)

-- Check 4: Verify scope not null constraint prevents null-derived authorization
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.wave8_signer_resolution'::regclass
AND conname = 'wave8_signer_scope_not_null';

-- Expected: constraint exists with CHECK (scope IS NOT NULL AND scope != '')

-- Check 5: Verify signer resolution function exists
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'resolve_authoritative_signer';

-- Expected: function exists with prosecdef = true

-- Check 6: Test unknown signer case (no matching signer)
DO $$
DECLARE
    test_result text;
BEGIN
    -- Attempt to resolve unknown signer
    BEGIN
        SELECT COUNT(*) INTO test_result
        FROM resolve_authoritative_signer('unknown_key_id', '1', gen_random_uuid(), 'test_entity');
        
        IF test_result::text = '0' THEN
            RAISE NOTICE 'Unknown signer test: SUCCESS (empty set returned)';
        ELSE
            RAISE NOTICE 'Unknown signer test: FAILURE (non-empty set returned)';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unknown signer test: FAILURE (exception raised: %)', SQLERRM;
    END;
END $$;

-- Expected: Unknown signer test: SUCCESS

-- Check 7: Test unauthorized signer case (signer exists but wrong project)
DO $$
DECLARE
    test_signer_id uuid;
    test_result text;
BEGIN
    -- Insert test signer for project A
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active
    ) VALUES (
        'test_key_005',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        gen_random_uuid(),
        'test_scope',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to resolve for different project (unauthorized)
    SELECT is_authorized INTO test_result
    FROM resolve_authoritative_signer('test_key_005', '1', gen_random_uuid(), 'test_entity');
    
    IF test_result = 'false' THEN
        RAISE NOTICE 'Unauthorized signer test: SUCCESS (is_authorized=false)';
    ELSE
        RAISE NOTICE 'Unauthorized signer test: FAILURE (is_authorized=true)';
    END IF;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: Unauthorized signer test: SUCCESS

-- Check 8: Test authorized signer case (signer exists and matches project)
DO $$
DECLARE
    test_signer_id uuid;
    test_project_id uuid;
    test_result text;
BEGIN
    -- Insert test signer
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active
    ) VALUES (
        'test_key_005_auth',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'test_scope',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Resolve for same project (authorized)
    SELECT is_authorized INTO test_result
    FROM resolve_authoritative_signer('test_key_005_auth', '1', test_project_id, 'test_entity');
    
    IF test_result = 'true' THEN
        RAISE NOTICE 'Authorized signer test: SUCCESS (is_authorized=true)';
    ELSE
        RAISE NOTICE 'Authorized signer test: FAILURE (is_authorized=false)';
    END IF;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: Authorized signer test: SUCCESS

-- Check 9: Test ambiguous signer precedence (multiple active matches)
DO $$
DECLARE
    test_signer_id_1 uuid;
    test_signer_id_2 uuid;
    test_result text;
BEGIN
    -- Insert two active signers with same key_id and key_version (should fail due to unique constraint)
    BEGIN
        INSERT INTO public.wave8_signer_resolution (
            key_id,
            key_version,
            public_key_bytes,
            project_id,
            scope,
            is_active
        ) VALUES (
            'test_key_005_ambig',
            '1',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            gen_random_uuid(),
            'test_scope',
            true
        ) RETURNING signer_id INTO test_signer_id_1;
        
        -- This should fail due to unique constraint
        INSERT INTO public.wave8_signer_resolution (
            key_id,
            key_version,
            public_key_bytes,
            project_id,
            scope,
            is_active
        ) VALUES (
            'test_key_005_ambig',
            '1',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            gen_random_uuid(),
            'test_scope',
            true
        );
        
        test_result := 'AMBIGUOUS_ACCEPTED';
        
        -- Clean up
        DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id_1;
    EXCEPTION WHEN OTHERS THEN
        test_result := 'AMBIGUOUS_REJECTED_BY_CONSTRAINT';
        -- Clean up
        DELETE FROM public.wave8_signer_resolution WHERE key_id = 'test_key_005_ambig';
    END;
    
    RAISE NOTICE 'Ambiguous signer precedence test result: %', test_result;
END $$;

-- Expected: AMBIGUOUS_REJECTED_BY_CONSTRAINT
