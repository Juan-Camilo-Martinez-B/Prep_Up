-- ==========================================
-- Prep_Up: Supabase Database Setup
-- ==========================================

-- 1. Tabla de Usuarios (Público)
-- Esta tabla extiende la funcionalidad de auth.users
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT,
  email TEXT UNIQUE,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 2. Tabla de Ajustes de la Aplicación
CREATE TABLE IF NOT EXISTS public.settings (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  theme_mode TEXT DEFAULT 'system',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 3. Tabla de Sesiones de Entrevista
CREATE TABLE IF NOT EXISTS public.interview_sessions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL, -- 'technical', 'hr', 'mixed'
  job_role TEXT NOT NULL,
  status TEXT NOT NULL, -- 'notStarted', 'inProgress', 'completed', 'analyzing'
  question_count INTEGER DEFAULT 0,
  time_limit_seconds INTEGER,
  video_reference TEXT,
  turns JSONB DEFAULT '[]'::jsonb, -- Almacena la lista de turnos (pregunta/respuesta/feedback)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 4. Tabla de Resultados de Entrevista
CREATE TABLE IF NOT EXISTS public.interview_results (
  id UUID PRIMARY KEY,
  session_id UUID REFERENCES public.interview_sessions(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  score INTEGER NOT NULL, -- Puntaje general (0-100)
  outcome TEXT,
  breakdown JSONB DEFAULT '{}'::jsonb, -- Puntajes por categoría (comunicación, técnico, etc.)
  highlights JSONB DEFAULT '[]'::jsonb, -- Puntos fuertes
  personalized_feedback TEXT,
  recommendations JSONB DEFAULT '[]'::jsonb,
  improvement_tips JSONB DEFAULT '[]'::jsonb,
  average_response_seconds FLOAT DEFAULT 0,
  total_response_seconds FLOAT DEFAULT 0,
  valid_answers_count INTEGER DEFAULT 0,
  analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 5. Habilitar Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_results ENABLE ROW LEVEL SECURITY;

-- 6. Políticas de Acceso (Seguridad)
-- Solo los dueños de los datos pueden verlos y modificarlos

-- Políticas para 'users'
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Políticas para 'settings'
CREATE POLICY "Users can view own settings" ON public.settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own settings" ON public.settings FOR ALL USING (auth.uid() = user_id);

-- Políticas para 'interview_sessions'
CREATE POLICY "Users can view own sessions" ON public.interview_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own sessions" ON public.interview_sessions FOR ALL USING (auth.uid() = user_id);

-- Políticas para 'interview_results'
CREATE POLICY "Users can view own results" ON public.interview_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own results" ON public.interview_results FOR ALL USING (auth.uid() = user_id);

-- 7. Función para Manejo Automático de Perfiles
-- Se ejecuta cuando un usuario se registra en Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertar en la tabla pública de usuarios
  INSERT INTO public.users (id, display_name, email, photo_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'display_name', 'Professional User'),
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url'
  );

  -- Crear fila de ajustes por defecto
  INSERT INTO public.settings (user_id, theme_mode)
  VALUES (NEW.id, 'system');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Trigger de Creación de Perfil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
