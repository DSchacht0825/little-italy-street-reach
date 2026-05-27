-- Add exit tracking fields to persons table
ALTER TABLE public.persons
ADD COLUMN IF NOT EXISTS exit_date DATE,
ADD COLUMN IF NOT EXISTS exit_destination TEXT,
ADD COLUMN IF NOT EXISTS exit_notes TEXT;

-- Add index for exit_date for reporting
CREATE INDEX idx_persons_exit_date ON public.persons(exit_date);
