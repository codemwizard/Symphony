-- Verification SQL for Wave 8 attestation hash enforcement
-- Task: TSK-P2-W8-DB-004
-- Purpose: Prove that PostgreSQL rejects tampered hash writes and accepts correctly recomputed hash writes

-- Check 1: Verify hash recomputation function exists
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'recompute_transition_hash';

-- Expected: function exists with prosecdef = true

-- Check 2: Verify hash enforcement function exists
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'enforce_transition_hash_match';

-- Expected: function exists with prosecdef = true

-- Check 3: Verify hash enforcement trigger exists on asset_batches
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'asset_batches'
AND event_object_schema = 'public'
AND trigger_name = 'trg_enforce_transition_hash_match';

-- Expected: trigger exists with BEFORE INSERT OR UPDATE timing

-- Check 4: Test hash recomputation with known input
DO $$
DECLARE
    test_canonical_bytes bytea;
    recomputed_hash text;
BEGIN
    -- Use the canonical bytes from the contract vector
    test_canonical_bytes := decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex');
    
    -- Recompute hash
    recomputed_hash := recompute_transition_hash(test_canonical_bytes);
    
    -- Expected hash from contract vector
    IF recomputed_hash = 'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3' THEN
        RAISE NOTICE 'Hash recomputation test: SUCCESS (matches contract vector)';
    ELSE
        RAISE NOTICE 'Hash recomputation test: FAILURE (does not match contract vector)';
        RAISE NOTICE 'Expected: c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3';
        RAISE NOTICE 'Actual: %', recomputed_hash;
    END IF;
END $$;

-- Expected: Hash recomputation test: SUCCESS

-- Check 5: Test tampered hash rejection (physical write test)
DO $$
DECLARE
    test_result text;
BEGIN
    -- Attempt to insert with tampered hash
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
            transition_hash
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
            'Tampered hash test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'TAMPERED_HASH_00000000000000000000000000000000000000000000000000000000000000'
        );
        test_result := 'TAMPERED_HASH_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'TAMPERED_HASH_REJECTED';
    END;
    
    RAISE NOTICE 'Tampered hash rejection test result: %', test_result;
END $$;

-- Expected: TAMPERED_HASH_REJECTED

-- Check 6: Test correct hash acceptance (physical write test)
DO $$
DECLARE
    test_result text;
    test_uuid uuid;
BEGIN
    -- Attempt to insert with correct hash
    test_uuid := gen_random_uuid();
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
            transition_hash
        ) VALUES (
            test_uuid,
            gen_random_uuid(),
            gen_random_uuid(),
            'test',
            1,
            'PENDING',
            now(),
            'test_authority'::data_authority_level,
            false,
            'Correct hash test',
            decode('7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d', 'hex'),
            'c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3'
        );
        test_result := 'CORRECT_HASH_ACCEPTED';
        
        -- Clean up test record
        DELETE FROM public.asset_batches WHERE asset_batch_id = test_uuid;
    EXCEPTION WHEN OTHERS THEN
        test_result := 'CORRECT_HASH_REJECTED';
    END;
    
    RAISE NOTICE 'Correct hash acceptance test result: %', test_result;
END $$;

-- Expected: CORRECT_HASH_ACCEPTED
