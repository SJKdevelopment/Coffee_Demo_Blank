-- ==========================================
-- LOYALTY REDEMPTION CODES TABLE
-- ==========================================

CREATE TABLE IF NOT EXISTS redemption_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL DEFAULT 'free_coffee',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    is_used BOOLEAN DEFAULT FALSE,
    
    -- Constraints
    CONSTRAINT redemption_codes_code_check CHECK (code ~ '^COFFEE[0-9]{6}$'),
    CONSTRAINT redemption_codes_type_check CHECK (type IN ('free_coffee'))
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_redemption_codes_code ON redemption_codes(code);
CREATE INDEX IF NOT EXISTS idx_redemption_codes_user_id ON redemption_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_redemption_codes_is_used ON redemption_codes(is_used);

-- Row Level Security (RLS)
ALTER TABLE redemption_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own redemption codes
CREATE POLICY "Users can view own redemption codes" ON redemption_codes
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert their own redemption codes
CREATE POLICY "Users can insert own redemption codes" ON redemption_codes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Admin users can view all redemption codes
CREATE POLICY "Admins can view all redemption codes" ON redemption_codes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND email = 'blisscoffeedev@gmail.com'
        )
    );

-- Policy: Admin users can update all redemption codes (for verification)
CREATE POLICY "Admins can update redemption codes" ON redemption_codes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND email = 'blisscoffeedev@gmail.com'
        )
    );
