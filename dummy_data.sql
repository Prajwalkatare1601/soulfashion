-- Insert 50 dummy customers with varying created_at dates
-- Note: You can run this in the Supabase SQL Editor

DO $$
DECLARE
    i INT;
    v_name TEXT;
    v_phone TEXT;
    v_date TIMESTAMP WITH TIME ZONE;
    v_status TEXT;
    v_names TEXT[] := ARRAY['Rahul S¯harma', 'Priya Patel', 'Ankit Verma', 'Sneha Reddy', 'Vikram Singh', 'Deepa Nair', 'Arjun Gupta', 'Kavita Iyer', 'Sanjay Mishra', 'Meera Rao', 'Rohan Das', 'Swati Kulkarni', 'Abhishek Joshi', 'Neha Malhotra', 'Manish Pandey', 'Pooja Hegde', 'Varun Dhawan', 'Shraddha Kapoor', 'Siddharth Bose', 'Aditi Rao', 'Karthik Raja', 'Aswathy Menon', 'Pranav Kulkarni', 'Tanvi Shah', 'Yash Vardhan', 'Isha Ambani', 'Rishabh Pant', 'Sakshi Dhoni', 'Hardik Pandya', 'Natasa Stankovic', 'Virat Kohli', 'Anushka Sharma', 'Rohit Sharma', 'Ritika Sajdeh', 'Shikhar Dhawan', 'Ayesha Mukherjee', 'KL Rahul', 'Athiya Shetty', 'Jasprit Bumrah', 'Sanjana Ganesan', 'Ravindra Jadeja', 'Reeva Solanki', 'MS Dhoni', 'Suresh Raina', 'Priyanka Raina', 'Yuvraj Singh', 'Hazel Keech', 'Harbhajan Singh', 'Geeta Basra', 'Zaheer Khan'];
BEGIN
    FOR i IN 1..50 LOOP
        -- Select a name from the list or fallback
        v_name := v_names[((i-1) % 50) + 1];
        v_phone := '+91 ' || floor(random() * 9000000000 + 1000000000)::TEXT;
        
        -- Distribute dates:
        -- 10 from last week
        -- 10 from last month
        -- 10 from last year
        -- 20 from few years ago
        IF i <= 10 THEN
            v_date := now() - (random() * interval '7 days');
        ELSIF i <= 20 THEN
            v_date := now() - (random() * interval '30 days');
        ELSIF i <= 30 THEN
            v_date := now() - (random() * interval '365 days');
        ELSE
            v_date := now() - (random() * interval '1000 days');
        END IF;

        -- Random status
        v_status := (ARRAY['ordered', 'completed', 'delivered'])[floor(random() * 3 + 1)];

        INSERT INTO customers (name, phone, created_at, order_status)
        VALUES (v_name, v_phone, v_date, v_status);
    END LOOP;
END $$;
