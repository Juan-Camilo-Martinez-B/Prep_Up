-- 1. Crear o actualizar la tabla de usuarios en el esquema público
CREATE TABLE IF NOT EXISTS public.usuarios (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE,
  phone TEXT,
  occupation TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

-- 3. Crear políticas de acceso
-- Borrar si ya existen para evitar duplicados
DROP POLICY IF EXISTS "Users can view own user data" ON public.usuarios;
DROP POLICY IF EXISTS "Users can update own user data" ON public.usuarios;

-- Los usuarios pueden leer sus propios datos
CREATE POLICY "Users can view own user data" ON public.usuarios
  FOR SELECT USING (auth.uid() = id);

-- Los usuarios pueden actualizar sus propios datos
CREATE POLICY "Users can update own user data" ON public.usuarios
  FOR UPDATE USING (auth.uid() = id);

-- 4. Función para manejar la inserción automática desde auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.usuarios (id, full_name, email, phone, occupation)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.email,
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'occupation'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Trigger para ejecutar la función después de un registro en auth.users
-- Primero borrarlo por si ya existe para recrearlo
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
