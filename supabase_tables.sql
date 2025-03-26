-- Drop existing tables if they exist
DROP TABLE IF EXISTS public.order_items;
DROP TABLE IF EXISTS public.orders;
DROP TABLE IF EXISTS public.cart_items;
DROP TABLE IF EXISTS public.csrf_tokens;
DROP TABLE IF EXISTS public.products;

-- Create products table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    discounted_price DECIMAL(10, 2),
    category TEXT,
    brand TEXT,
    image_url TEXT,
    rating DECIMAL(3, 2),
    in_stock BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create cart_items table
CREATE TABLE IF NOT EXISTS public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (user_id, product_id)
);

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    shipping_address JSONB NOT NULL,
    payment_method TEXT NOT NULL,
    payment_details JSONB,
    subtotal DECIMAL(10, 2) NOT NULL,
    shipping_cost DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'processing',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    discounted_price DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create CSRF token table
CREATE TABLE IF NOT EXISTS public.csrf_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    token TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + interval '1 hour')
);

-- Create function to generate CSRF token
CREATE OR REPLACE FUNCTION public.create_csrf_token(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    token TEXT;
BEGIN
    -- Generate a random token
    token := encode(gen_random_bytes(32), 'hex');
    
    -- Delete any existing tokens for this user
    DELETE FROM public.csrf_tokens WHERE user_id = create_csrf_token.user_id;
    
    -- Insert the new token
    INSERT INTO public.csrf_tokens (user_id, token)
    VALUES (create_csrf_token.user_id, token);
    
    RETURN token;
END;
$$;

-- Create function to validate CSRF token
CREATE OR REPLACE FUNCTION public.validate_csrf_token(input_token TEXT, user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    valid BOOLEAN;
BEGIN
    -- Check if token exists, is not expired, and belongs to the user
    SELECT EXISTS (
        SELECT 1 
        FROM public.csrf_tokens 
        WHERE 
            token = input_token AND 
            user_id = validate_csrf_token.user_id AND
            expires_at > now()
    ) INTO valid;
    
    -- Delete the token if it was found (one-time use)
    IF valid THEN
        DELETE FROM public.csrf_tokens 
        WHERE token = input_token AND user_id = validate_csrf_token.user_id;
    END IF;
    
    RETURN valid;
END;
$$;

-- Sample product data
INSERT INTO public.products (name, description, price, discounted_price, category, brand, image_url, rating)
VALUES
('iPhone 14 Pro', 'Latest iPhone with amazing features', 999.99, 949.99, 'Electronics', 'Apple', 'https://example.com/iphone14.jpg', 4.8),
('Samsung Galaxy S23', 'Powerful Android smartphone', 899.99, 849.99, 'Electronics', 'Samsung', 'https://example.com/galaxys23.jpg', 4.7),
('Nike Air Max', 'Comfortable athletic shoes', 129.99, 99.99, 'Footwear', 'Nike', 'https://example.com/airmax.jpg', 4.5),
('Sony WH-1000XM5', 'Premium noise-canceling headphones', 349.99, 299.99, 'Electronics', 'Sony', 'https://example.com/sony-headphones.jpg', 4.9),
('Kindle Paperwhite', 'E-reader with adjustable light', 139.99, 119.99, 'Electronics', 'Amazon', 'https://example.com/kindle.jpg', 4.6),
('Levi\'s 501 Jeans', 'Classic straight fit jeans', 69.99, 49.99, 'Clothing', 'Levi\'s', 'https://example.com/levis.jpg', 4.4);

-- Add Row Level Security (RLS) policies

-- Policy for cart_items: Users can only see and modify their own cart items
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY cart_items_select_policy ON public.cart_items 
    FOR SELECT USING (auth.uid() = user_id);
    
CREATE POLICY cart_items_insert_policy ON public.cart_items 
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    
CREATE POLICY cart_items_update_policy ON public.cart_items 
    FOR UPDATE USING (auth.uid() = user_id);
    
CREATE POLICY cart_items_delete_policy ON public.cart_items 
    FOR DELETE USING (auth.uid() = user_id);

-- Policy for orders: Users can only see and create their own orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY orders_select_policy ON public.orders 
    FOR SELECT USING (auth.uid() = user_id);
    
CREATE POLICY orders_insert_policy ON public.orders 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for order_items: No direct access, handled through orders
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY order_items_select_policy ON public.order_items 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Policy for CSRF tokens: Users can only see their own tokens
ALTER TABLE public.csrf_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY csrf_tokens_select_policy ON public.csrf_tokens 
    FOR SELECT USING (auth.uid() = user_id); 