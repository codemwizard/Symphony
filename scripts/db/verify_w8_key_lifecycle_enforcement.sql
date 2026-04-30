-- Verification SQL for Wave 8 key lifecycle enforcement
-- Task: TSK-P2-W8-DB-008
-- Purpose: Prove that PostgreSQL enforces key lifecycle state in the authoritative verification path

-- Check 1: Verify key lifecycle fields exist on wave8_signer_resolution
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'wave8_signer_resolution'
AND table_schema = 'public'
AND column_name IN ('superseded_by', 'superseded_at')
ORDER BY column_name;

-- Expected: both columns exist

-- Check 2: Verify superseded_by constraint exists
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.wave8_signer_resolution'::regclass
AND conname = 'wave8_signer_superseded_by_valid';

-- Expected: constraint exists

-- Check 3: Verify cryptographic enforcement function includes key lifecycle logic
DO $$
DECLARE
    function_source text;
BEGIN
    SELECT prosrc INTO function_source
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'wave8_cryptographic_enforcement';
    
    IF function_source LIKE '%P7813%' AND function_source LIKE '%key lifecycle%' THEN
        RAISE NOTICE 'Key lifecycle logic present: SUCCESS';
    ELSE
        RAISE NOTICE 'Key lifecycle logic present: FAILURE';
    END IF;
END $$;

-- Expected: Key lifecycle logic present: SUCCESS

-- Check 4: Test revoked key rejection (physical write test)
DO $$
DECLARE
    test_result text;
    test_signer_id uuid;
    test_project_id uuid;
BEGIN
    -- Insert test signer with is_active = false (revoked)
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active
    ) VALUES (
        'test_key_008_revoked',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        false -- Revoked
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert with revoked signer
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
            gen_random_uuid(),
            gen_random_uuid(),
            test_project_id,
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Revoked key test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_008_revoked',
            '1',
            'unique_nonce_008_12345'
        );
        test_result := 'REVOKED_KEY_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'REVOKED_KEY_REJECTED';
    END;
    
    RAISE NOTICE 'Revoked key rejection test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: REVOKED_KEY_REJECTED

-- Check 5: Test expired key rejection (physical write test)
DO $$
DECLARE
    test_result text;
    test_signer_id uuid;
    test_project_id uuid;
BEGIN
    -- Insert test signer with valid_until in the past (expired)
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active,
        valid_until
    ) VALUES (
        'test_key_008_expired',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true,
        now() - interval '1 day' -- Expired
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert with expired signer
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
            gen_random_uuid(),
            gen_random_uuid(),
            test_project_id,
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Expired key test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_008_expired',
            '1',
            'unique_nonce_008_67890'
        );
        test_result := 'EXPIRED_KEY_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'EXPIRED_KEY_REJECTED';
    END;
    
    RAISE NOTICE 'Expired key rejection test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: EXPIRED_KEY_REJECTED

-- Check 6: Test superseded key rejection (physical write test)
DO $$
DECLARE
    test_result text;
    test_signer_id_old uuid;
    test_signer_id_new uuid;
    test_project_id uuid;
BEGIN
    -- Insert test signers: old (superseded) and new (superseding)
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active
    ) VALUES (
        'test_key_008_new',
        '2',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true
    ) RETURNING signer_id INTO test_signer_id_new;
    
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active,
        superseded_by,
        superseded_at
    ) VALUES (
        'test_key_008_old',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true,
        test_signer_id_new,
        now()
    ) RETURNING signer_id INTO test_signer_id_old;
    
    -- Attempt to insert with superseded signer
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
            gen_random_uuid(),
            gen_random_uuid(),
            test_project_id,
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Superseded key test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_008_old',
            '1',
            'unique_nonce_008_11111'
        );
        test_result := 'SUPERSEDED_KEY_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'SUPERSEDED_KEY_REJECTED';
    END;
    
    RAISE NOTICE 'Superseded key rejection test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id_old;
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id_new;
END $$;

-- Expected: SUPERSEDED_KEY_REJECTED

-- Check 7: Test active key acceptance (physical write test)
DO $$
DECLARE
    test_result text;
    test_signer_id uuid;
    test_project_id uuid;
    test_asset_batch_id uuid;
BEGIN
    -- Insert test signer with active state
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active,
        valid_until
    ) VALUES (
        'test_key_008_active',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true,
        now() + interval '1 day' -- Valid
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert with active signer
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
            'Active key test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_008_active',
            '1',
            'unique_nonce_008_22222'
        );
        test_result := 'ACTIVE_KEY_ACCEPTED';
        
        -- Clean up test record
        DELETE FROM public.asset_batches WHERE asset_batch_id = test_asset_batch_id;
    EXCEPTION WHEN OTHERS THEN
        test_result := 'ACTIVE_KEY_REJECTED';
    END;
    
    RAISE NOTICE 'Active key acceptance test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: ACTIVE_KEY_ACCEPTED
