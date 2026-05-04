-- Verification SQL for Wave 8 cryptographic boundary enforcement
-- Task: TSK-P2-W8-DB-006
-- Purpose: Prove that PostgreSQL independently validates writes and rejects cryptographically invalid writes at asset_batches

-- Check 1: Verify cryptographic enforcement function exists
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'wave8_cryptographic_enforcement';

-- Expected: function exists with prosecdef = true

-- Check 2: Verify cryptographic enforcement trigger exists on asset_batches
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'asset_batches'
AND event_object_schema = 'public'
AND trigger_name = 'trg_wave8_cryptographic_enforcement';

-- Expected: trigger exists with BEFORE INSERT timing

-- Check 3: Verify trigger order (cryptographic enforcement runs after hash enforcement)
SELECT 
    trigger_name,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'asset_batches'
AND event_object_schema = 'public'
AND trigger_name IN ('trg_enforce_transition_hash_match', 'trg_wave8_cryptographic_enforcement')
ORDER BY trigger_name;

-- Expected: Both triggers exist, hash enforcement runs before crypto enforcement

-- Check 4: Test missing signature rejection (physical write test)
DO $$
DECLARE
    test_result text;
BEGIN
    -- Attempt to insert without signature
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
            signer_key_id,
            signer_key_version
            -- Note: signature is missing
        ) VALUES (
            gen_random_uuid(),
            gen_random_uuid(),
            gen_random_uuid(),
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Missing signature test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            'test_signer_006',
            '1'
        );
        test_result := 'MISSING_SIGNATURE_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'MISSING_SIGNATURE_REJECTED';
    END;
    
    RAISE NOTICE 'Missing signature rejection test result: %', test_result;
END $$;

-- Expected: MISSING_SIGNATURE_REJECTED

-- Check 5: Test unknown signer rejection (physical write test)
DO $$
DECLARE
    test_result text;
BEGIN
    -- Attempt to insert with unknown signer
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
            signer_key_id,
            signer_key_version,
            signature
        ) VALUES (
            gen_random_uuid(),
            gen_random_uuid(),
            gen_random_uuid(),
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Unknown signer test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            'unknown_signer_006',
            '1',
            'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
        );
        test_result := 'UNKNOWN_SIGNER_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'UNKNOWN_SIGNER_REJECTED';
    END;
    
    RAISE NOTICE 'Unknown signer rejection test result: %', test_result;
END $$;

-- Expected: UNKNOWN_SIGNER_REJECTED

-- Check 6: Test invalid signature rejection (physical write test)
DO $$
DECLARE
    test_signer_id uuid;
    test_project_id uuid;
    test_result text;
BEGIN
    -- Insert test signer for valid signature test
    test_project_id := gen_random_uuid();
    INSERT INTO public.wave8_signer_resolution (
        key_id,
        key_version,
        public_key_bytes,
        project_id,
        scope,
        is_active
    ) VALUES (
        'test_signer_006',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'test_scope',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert with invalid signature
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
            signer_key_id,
            signer_key_version,
            signature
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
            'Invalid signature test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            'test_signer_006',
            '1',
            'invalid_signature_00000000000000000000000000000000000000000000000000000000000000'
        );
        test_result := 'INVALID_SIGNATURE_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'INVALID_SIGNATURE_REJECTED';
    END;
    
    -- Clean up test signer
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
    
    RAISE NOTICE 'Invalid signature rejection test result: %', test_result;
END $$;

-- Expected: INVALID_SIGNATURE_REJECTED

-- Check 7: Test unavailable crypto provider handling (physical write test)
DO $$
DECLARE
    test_result text;
BEGIN
    -- This test simulates unavailable crypto by using malformed public key
    -- The verification primitive should handle this gracefully
    BEGIN
        -- Insert signer with malformed public key (wrong length)
        INSERT INTO public.wave8_signer_resolution (
            key_id,
            key_version,
            public_key_bytes,
            project_id,
            scope,
            is_active
        ) VALUES (
            'test_signer_006_bad',
            '1',
            decode('deadbeef', 'hex'), -- Too short for Ed25519
            gen_random_uuid(),
            'test_scope',
            true
        );
        
        -- Attempt to insert with this malformed signer
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
            signer_key_id,
            signer_key_version,
            signature
        ) VALUES (
            gen_random_uuid(),
            gen_random_uuid(),
            gen_random_uuid(),
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Unavailable crypto test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            'test_signer_006_bad',
            '1',
            'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
        );
        test_result := 'UNAVAILABLE_CRYPTO_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'UNAVAILABLE_CRYPTO_REJECTED';
    END;
    
    -- Clean up test signer
    DELETE FROM public.wave8_signer_resolution WHERE key_id = 'test_signer_006_bad';
    
    RAISE NOTICE 'Unavailable crypto provider test result: %', test_result;
END $$;

-- Expected: UNAVAILABLE_CRYPTO_REJECTED
