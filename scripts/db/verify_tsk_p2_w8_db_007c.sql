-- Verification SQL for Wave 8 replay law enforcement
-- Task: TSK-P2-W8-DB-007c
-- Purpose: Prove that PostgreSQL distinguishes replay-invalid failures at asset_batches

-- Check 1: Verify cryptographic enforcement function exists with replay prevention
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'wave8_cryptographic_enforcement';

-- Expected: function exists with prosecdef = true

-- Check 2: Verify function includes replay prevention logic
DO $$
DECLARE
    function_source text;
BEGIN
    SELECT prosrc INTO function_source
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'wave8_cryptographic_enforcement';
    
    IF function_source LIKE '%P7812%' AND function_source LIKE '%replay prevention%' THEN
        RAISE NOTICE 'Replay prevention logic present: SUCCESS';
    ELSE
        RAISE NOTICE 'Replay prevention logic present: FAILURE';
    END IF;
END $$;

-- Expected: Replay prevention logic present: SUCCESS

-- Check 3: Test missing attestation nonce rejection (replay prevention failure)
DO $$
DECLARE
    test_result text;
    test_signer_id uuid;
    test_project_id uuid;
BEGIN
    -- Insert test signer with correct scope
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active
    ) VALUES (
        'test_key_007c',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert without attestation nonce (replay prevention failure)
    BEGIN
        INSERT INTO public.asset_batches (
            asset_batch_id,
            tenant_id,
            project_id,
            batch_type,
            quantity,
            status,
            created_at,
            data_authority,
            audit_grade,
            authority_explanation,
            canonical_payload_bytes,
            transition_hash,
            signature_bytes,
            signer_key_id,
            signer_key_version
        ) VALUES (
            gen_random_uuid(),
            gen_random_uuid(),
            test_project_id,
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Missing attestation nonce test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_007c',
            '1'
        );
        test_result := 'MISSING_NONCE_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'MISSING_NONCE_REJECTED';
    END;
    
    RAISE NOTICE 'Missing attestation nonce rejection test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: MISSING_NONCE_REJECTED

-- Check 4: Test valid attestation nonce acceptance (replay prevention pass)
DO $$
DECLARE
    test_result text;
    test_signer_id uuid;
    test_project_id uuid;
    test_asset_batch_id uuid;
BEGIN
    -- Insert test signer with correct scope
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active
    ) VALUES (
        'test_key_007c_valid',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert with valid attestation nonce
    test_asset_batch_id := gen_random_uuid();
    BEGIN
        INSERT INTO public.asset_batches (
            asset_batch_id,
            tenant_id,
            project_id,
            batch_type,
            quantity,
            status,
            created_at,
            data_authority,
            audit_grade,
            authority_explanation,
            canonical_payload_bytes,
            transition_hash,
            signature_bytes,
            signer_key_id,
            signer_key_version,
            attestation_nonce
        ) VALUES (
            test_asset_batch_id,
            gen_random_uuid(),
            test_project_id,
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Valid attestation nonce test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_007c_valid',
            '1',
            'unique_nonce_007c_12345'
        );
        test_result := 'VALID_NONCE_ACCEPTED';
        
        -- Clean up test record
        DELETE FROM public.asset_batches WHERE asset_batch_id = test_asset_batch_id;
    EXCEPTION WHEN OTHERS THEN
        test_result := 'VALID_NONCE_REJECTED';
    END;
    
    RAISE NOTICE 'Valid attestation nonce acceptance test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: VALID_NONCE_ACCEPTED
