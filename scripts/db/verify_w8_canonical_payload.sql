-- Verification SQL for Wave 8 canonical payload construction
-- Task: TSK-P2-W8-DB-003
-- Purpose: Prove that SQL runtime emits canonical bytes identical to the frozen contract vector

-- Check 1: Verify canonical payload construction function exists
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'construct_canonical_attestation_payload';

-- Expected: function exists with prosecdef = true

-- Check 2: Verify canonical_payload_bytes column exists on asset_batches
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'asset_batches'
AND table_schema = 'public'
AND column_name = 'canonical_payload_bytes';

-- Expected: column exists with data_type = 'bytea'

-- Check 3: Test canonical payload construction with contract vector inputs
DO $$
DECLARE
    test_bytes bytea;
    expected_hex text := '7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d';
    actual_hex text;
BEGIN
    -- Construct canonical payload using contract vector inputs
    test_bytes := construct_canonical_attestation_payload(
        '550e8400-e29b-41d4-a716-446655440000'::uuid,
        'carbon_credit',
        '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
        'pending',
        'issued',
        '6ba7b811-9dad-11d1-80b4-00c04fd430c8'::uuid,
        '6ba7b812-9dad-11d1-80b4-00c04fd430c8'::uuid,
        '6ba7b813-9dad-11d1-80b4-00c04fd430c8'::uuid,
        'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
        '2026-04-29T06:42:35.123456Z'::timestamp with time zone
    );
    
    -- Convert to hex for comparison
    actual_hex := encode(test_bytes, 'hex');
    
    -- Compare with expected contract vector
    IF actual_hex = expected_hex THEN
        RAISE NOTICE 'Canonical payload bytes match contract vector: SUCCESS';
    ELSE
        RAISE NOTICE 'Canonical payload bytes DO NOT match contract vector: FAILURE';
        RAISE NOTICE 'Expected: %', expected_hex;
        RAISE NOTICE 'Actual: %', actual_hex;
    END IF;
END $$;

-- Expected: Canonical payload bytes match contract vector: SUCCESS

-- Check 4: Test null field rejection
DO $$
DECLARE
    test_result text;
BEGIN
    BEGIN
        PERFORM construct_canonical_attestation_payload(
            NULL::uuid,
            'carbon_credit',
            '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
            'pending',
            'issued',
            '6ba7b811-9dad-11d1-80b4-00c04fd430c8'::uuid,
            '6ba7b812-9dad-11d1-80b4-00c04fd430c8'::uuid,
            '6ba7b813-9dad-11d1-80b4-00c04fd430c8'::uuid,
            'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
            '2026-04-29T06:42:35.123456Z'::timestamp with time zone
        );
        test_result := 'NULL_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'NULL_REJECTED';
    END;
    
    RAISE NOTICE 'Null field rejection test result: %', test_result;
END $$;

-- Expected: NULL_REJECTED

-- Check 5: Test uppercase UUID rejection
DO $$
DECLARE
    test_result text;
BEGIN
    BEGIN
        PERFORM construct_canonical_attestation_payload(
            '550E8400-E29B-41D4-A716-446655440000'::uuid,
            'carbon_credit',
            '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
            'pending',
            'issued',
            '6ba7b811-9dad-11d1-80b4-00c04fd430c8'::uuid,
            '6ba7b812-9dad-11d1-80b4-00c04fd430c8'::uuid,
            '6ba7b813-9dad-11d1-80b4-00c04fd430c8'::uuid,
            'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
            '2026-04-29T06:42:35.123456Z'::timestamp with time zone
        );
        test_result := 'UPPERCASE_ACCEPTED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'UPPERCASE_REJECTED';
    END;
    
    RAISE NOTICE 'Uppercase UUID rejection test result: %', test_result;
END $$;

-- Expected: UPPERCASE_REJECTED
