
-- Tic-Tac-Toe 
-- Public API:
--   1) NewGame()            -> starts a new game, returns board
--   2) NextMove(x, y)       -> makes next move (auto X/O), returns board
--
-- Board storage requirement:
--   Each cell is stored as a separate row in table ttt_cell.
--
-- Behavior requirement:
--   If game not over -> returns current board state
--   If game over     -> displays result (RAISE NOTICE) and returns final board
-- 
DROP FUNCTION IF EXISTS NextMove(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS NewGame() CASCADE;
DROP FUNCTION IF EXISTS ttt_render_board(INT) CASCADE;
DROP FUNCTION IF EXISTS ttt_check_status(INT) CASCADE;

DROP TABLE IF EXISTS ttt_cell CASCADE;
DROP TABLE IF EXISTS ttt_game CASCADE;
DROP TABLE IF EXISTS ttt_session CASCADE;

CREATE TABLE ttt_session (
  id              BOOLEAN PRIMARY KEY DEFAULT TRUE,
  active_game_id  BIGINT NULL
);

INSERT INTO ttt_session(id, active_game_id) VALUES (TRUE, NULL)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE ttt_game (
  game_id      BIGSERIAL PRIMARY KEY,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  status       TEXT NOT NULL DEFAULT 'IN_PROGRESS', 
  next_player  CHAR(1) NOT NULL DEFAULT 'X'         
);

CREATE TABLE ttt_cell (
  game_id  BIGINT NOT NULL REFERENCES ttt_game(game_id) ON DELETE CASCADE,
  x        INT NOT NULL CHECK (x BETWEEN 1 AND 3),
  y        INT NOT NULL CHECK (y BETWEEN 1 AND 3),
  val      CHAR(1) NULL CHECK (val IN ('X','O')),
  PRIMARY KEY (game_id, x, y)
);

CREATE INDEX ON ttt_cell(game_id);
CREATE OR REPLACE FUNCTION ttt_render_board(p_game_id BIGINT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  r1 TEXT;
  r2 TEXT;
  r3 TEXT;
  c11 TEXT; c21 TEXT; c31 TEXT;
  c12 TEXT; c22 TEXT; c32 TEXT;
  c13 TEXT; c23 TEXT; c33 TEXT;
BEGIN
  SELECT COALESCE(MAX(CASE WHEN x=1 AND y=1 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=2 AND y=1 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=3 AND y=1 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=1 AND y=2 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=2 AND y=2 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=3 AND y=2 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=1 AND y=3 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=2 AND y=3 THEN val END),' ')::TEXT,
         COALESCE(MAX(CASE WHEN x=3 AND y=3 THEN val END),' ')::TEXT
    INTO c11,c21,c31,c12,c22,c32,c13,c23,c33
  FROM ttt_cell
  WHERE game_id = p_game_id;

  r1 := ' '||c11||' | '||c21||' | '||c31||' ';
  r2 := ' '||c12||' | '||c22||' | '||c32||' ';
  r3 := ' '||c13||' | '||c23||' | '||c33||' ';

  RETURN r1 || E'\n' || '---+---+---' || E'\n' || r2 || E'\n' || '---+---+---' || E'\n' || r3;
END;
$$;

CREATE OR REPLACE FUNCTION ttt_check_status(p_game_id BIGINT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  winner CHAR(1);
  filled_count INT;
BEGIN
  WITH lines AS (
    SELECT 1 AS line_id,
           MAX(CASE WHEN x=1 AND y=1 THEN val END) AS a,
           MAX(CASE WHEN x=2 AND y=1 THEN val END) AS b,
           MAX(CASE WHEN x=3 AND y=1 THEN val END) AS c
      FROM ttt_cell WHERE game_id=p_game_id
    UNION ALL
    SELECT 2,
           MAX(CASE WHEN x=1 AND y=2 THEN val END),
           MAX(CASE WHEN x=2 AND y=2 THEN val END),
           MAX(CASE WHEN x=3 AND y=2 THEN val END)
      FROM ttt_cell WHERE game_id=p_game_id
    UNION ALL
    SELECT 3,
           MAX(CASE WHEN x=1 AND y=3 THEN val END),
           MAX(CASE WHEN x=2 AND y=3 THEN val END),
           MAX(CASE WHEN x=3 AND y=3 THEN val END)
      FROM ttt_cell WHERE game_id=p_game_id

    -- Columns
    UNION ALL
    SELECT 4,
           MAX(CASE WHEN x=1 AND y=1 THEN val END),
           MAX(CASE WHEN x=1 AND y=2 THEN val END),
           MAX(CASE WHEN x=1 AND y=3 THEN val END)
      FROM ttt_cell WHERE game_id=p_game_id
    UNION ALL
    SELECT 5,
           MAX(CASE WHEN x=2 AND y=1 THEN val END),
           MAX(CASE WHEN x=2 AND y=2 THEN val END),
           MAX(CASE WHEN x=2 AND y=3 THEN val END)
      FROM ttt_cell WHERE game_id=p_game_id
    UNION ALL
    SELECT 6,
           MAX(CASE WHEN x=3 AND y=1 THEN val END),
           MAX(CASE WHEN x=3 AND y=2 THEN val END),
           MAX(CASE WHEN x=3 AND y=3 THEN val END)
      FROM ttt_cell WHERE game_id=p_game_id

    UNION ALL
    SELECT 7,
           MAX(CASE WHEN x=1 AND y=1 THEN val END),
           MAX(CASE WHEN x=2 AND y=2 THEN val END),
           MAX(CASE WHEN x=3 AND y=3 THEN val END)
      FROM ttt_cell WHERE game_id=p_game_id
    UNION ALL
    SELECT 8,
           MAX(CASE WHEN x=3 AND y=1 THEN val END),
           MAX(CASE WHEN x=2 AND y=2 THEN val END),
           MAX(CASE WHEN x=1 AND y=3 THEN val END)
      FROM ttt_cell WHERE game_id=p_game_id
  )
  SELECT a
    INTO winner
  FROM lines
  WHERE a IS NOT NULL AND a = b AND b = c
  LIMIT 1;

  IF winner = 'X' THEN
    RETURN 'X_WON';
  ELSIF winner = 'O' THEN
    RETURN 'O_WON';
  END IF;

  SELECT COUNT(*) INTO filled_count
  FROM ttt_cell
  WHERE game_id = p_game_id
    AND val IS NOT NULL;

  IF filled_count = 9 THEN
    RETURN 'DRAW';
  END IF;

  RETURN 'IN_PROGRESS';
END;
$$;

CREATE OR REPLACE FUNCTION NewGame()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  gid BIGINT;
BEGIN
  INSERT INTO ttt_game(status, next_player)
  VALUES ('IN_PROGRESS', 'X')
  RETURNING game_id INTO gid;

  INSERT INTO ttt_cell(game_id, x, y, val)
  SELECT gid, x, y, NULL::CHAR(1)
  FROM generate_series(1,3) AS x
  CROSS JOIN generate_series(1,3) AS y;

  UPDATE ttt_session SET active_game_id = gid WHERE id = TRUE;

  RETURN ttt_render_board(gid);
END;
$$;

CREATE OR REPLACE FUNCTION NextMove(p_x INT, p_y INT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  gid BIGINT;
  g_status TEXT;
  player CHAR(1);
  new_status TEXT;
  out_board TEXT;
BEGIN
  SELECT active_game_id INTO gid
  FROM ttt_session
  WHERE id = TRUE;

  IF gid IS NULL THEN
    RAISE EXCEPTION 'No active game. Call NewGame() first.';
  END IF;

  SELECT status, next_player INTO g_status, player
  FROM ttt_game
  WHERE game_id = gid;

  IF g_status <> 'IN_PROGRESS' THEN
    RAISE EXCEPTION 'Game % is already over (%). Start a new one with NewGame().', gid, g_status;
  END IF;

  IF p_x NOT BETWEEN 1 AND 3 OR p_y NOT BETWEEN 1 AND 3 THEN
    RAISE EXCEPTION 'Coordinates out of range. Use x,y in 1..3.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM ttt_cell
    WHERE game_id = gid AND x = p_x AND y = p_y AND val IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Cell (%, %) is already occupied.', p_x, p_y;
  END IF;

  UPDATE ttt_cell
  SET val = player
  WHERE game_id = gid AND x = p_x AND y = p_y;

  new_status := ttt_check_status(gid);

  UPDATE ttt_game
  SET status = new_status,
      next_player = CASE
                      WHEN new_status = 'IN_PROGRESS'
                        THEN CASE WHEN player = 'X' THEN 'O' ELSE 'X' END
                      ELSE next_player
                    END
  WHERE game_id = gid;

  out_board := ttt_render_board(gid);

  IF new_status = 'IN_PROGRESS' THEN
    RETURN out_board;
  END IF;

  IF new_status = 'X_WON' THEN
    RAISE NOTICE 'Game Over: X wins!';
    RETURN out_board || E'\n\nResult: X wins!';
  ELSIF new_status = 'O_WON' THEN
    RAISE NOTICE 'Game Over: O wins!';
    RETURN out_board || E'\n\nResult: O wins!';
  ELSE
    RAISE NOTICE 'Game Over: Draw.';
    RETURN out_board || E'\n\nResult: Draw.';
  END IF;
END;
$$;

--Check the game
SELECT NewGame();
Select NextMove(1,1);
Select NextMove(2,1);
Select NextMove(1,2);
Select NextMove(2,2);
Select NextMove(1,3);
