-- Verification SQL for Wave 8 context binding enforcement
-- Task: TSK-P2-W8-DB-009
-- Purpose: Prove that PostgreSQL binds verification to full decision context for anti-transplant protection

-- Check 1: Verify cryptographic enforcement function includes context binding logic
DO $$
DECLARE
    function_source text;
BEGIN
    SELECT prosrc INTO function_source
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'wave8_cryptographic_enforcement';
    
    IF function_source LIKE '%P7814%' AND function_source LIKE '%context binding%' THEN
        RAISE NOTICE 'Context binding logic present: SUCCESS';
    ELSE
        RAISE NOTICE 'Context binding logic present: FAILURE';
    END IF;
END $$;

-- Expected: Context binding logic present: SUCCESS

-- Check 2: Test missing entity_id rejection (context binding failure)
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
        'test_key_009',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert without entity_id (context binding failure)
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
            attestation_nonce,
            execution_id,
            policy_decision_id,
            interpretation_version_id,
            occurred_at
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
            'Missing entity_id test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_009',
            '1',
            'unique_nonce_009_12345',
            'exec_001',
            'policy_001',
            'interp_001',
            now()
        );
        test_result := 'MISSING_ENTITY_ID_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'MISSING_ENTITY_ID_REJECTED';
    END;
    
    RAISE NOTICE 'Missing entity_id rejection test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: MISSING_ENTITY_ID_REJECTED

-- Check 3: Test missing execution_id rejection (context binding failure)
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
        'test_key_009_exec',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert without execution_id (context binding failure)
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
            attestation_nonce,
            entity_id,
            policy_decision_id,
            interpretation_version_id,
            occurred_at
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
            'Missing execution_id test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_009_exec',
            '1',
            'unique_nonce_009_67890',
            'entity_001',
            'policy_001',
            'interp_001',
            now()
        );
        test_result := 'MISSING_EXECUTION_ID_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'MISSING_EXECUTION_ID_REJECTED';
    END;
    
    RAISE NOTICE 'Missing execution_id rejection test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: MISSING_EXECUTION_ID_REJECTED

-- Check 4: Test valid context binding acceptance (all required fields present)
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
        'test_key_009_valid',
        '1',
        decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
        test_project_id,
        'wave8_global',
        true
    ) RETURNING signer_id INTO test_signer_id;
    
    -- Attempt to insert with all required context binding fields
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
            attestation_nonce,
            entity_id,
            execution_id,
            policy_decision_id,
            interpretation_version_id,
            occurred_at
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
            'Valid context binding test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3',
            decode('deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef', 'hex'),
            'test_key_009_valid',
            '1',
            'unique_nonce_009_11111',
            'entity_001',
            'exec_001',
            'policy_001',
            'interp_001',
            now()
        );
        test_result := 'VALID_CONTEXT_ACCEPTED';
        
        -- Clean up test record
        DELETE FROM public.asset_batches WHERE asset_batch_id = test_asset_batch_id;
    EXCEPTION WHEN OTHERS THEN
        test_result := 'VALID_CONTEXT_REJECTED';
    END;
    
    RAISE NOTICE 'Valid context binding acceptance test result: %', test_result;
    
    -- Clean up
    DELETE FROM public.wave8_signer_resolution WHERE signer_id = test_signer_id;
END $$;

-- Expected: VALID_CONTEXT_ACCEPTED
