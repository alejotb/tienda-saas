-- Crear tabla Base (Contenido)
CREATE TABLE notificaciones_base (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  tipo TEXT,
  link TEXT,
  metadata_accion JSONB,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Estado (Usuario-Notificación)
CREATE TABLE notificaciones_usuario (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id UUID REFERENCES notificaciones_base(id),
  user_id UUID REFERENCES usuarios(id), 
  leido BOOLEAN DEFAULT FALSE,
  fecha_lectura TIMESTAMP WITH TIME ZONE
);
