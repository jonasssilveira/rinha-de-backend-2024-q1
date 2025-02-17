CREATE UNLOGGED TABLE users (
  id SERIAL PRIMARY KEY,
  limite INTEGER NOT NULL,
  saldo INTEGER NOT NULL
);

INSERT INTO users(limite, saldo)
VALUES
  (100000, 0),
  (80000, 0),
  (1000000, 0),
  (10000000, 0),
  (500000, 0);
CREATE TYPE tipot AS ENUM ('C', 'D');
CREATE UNLOGGED TABLE ledger (
  id SERIAL PRIMARY KEY,
  id_cliente INTEGER NOT NULL,
  valor INTEGER NOT NULL,
  tipo tipot NOT NULL,
  descricao VARCHAR(10) NOT NULL,
  realizada_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_cliente) REFERENCES users(id)
);

CREATE INDEX realizada_idx ON ledger(realizada_em DESC, id_cliente);
CREATE PROCEDURE poe(
  idc INTEGER,
  v INTEGER,
  d VARCHAR(10),
  INOUT saldo_atual INTEGER = NULL,
  INOUT limite_atual INTEGER = NULL
)
LANGUAGE plpgsql AS
$$
BEGIN
  PERFORM pg_advisory_xact_lock(idc);

  INSERT INTO ledger (
    id_cliente,
    valor,
    tipo,
    descricao
  ) VALUES (idc, v, 'C', d);

  UPDATE users
  SET saldo = saldo + v
    WHERE users.id = idc
    RETURNING saldo, limite INTO saldo_atual, limite_atual;
  COMMIT;
END;
$$;

CREATE PROCEDURE tira(
  idc INTEGER,
  v INTEGER,
  d VARCHAR(10),
  INOUT saldo_atual INTEGER = NULL,
  INOUT limite_atual INTEGER = NULL
)
LANGUAGE plpgsql AS
$$
BEGIN
  PERFORM pg_advisory_xact_lock(idc);

  SELECT limite, saldo INTO limite_atual, saldo_atual
  FROM users
  WHERE id = idc;

  IF saldo_atual - v >= limite_atual * -1 THEN
    INSERT INTO ledger (
      id_cliente,
      valor,
      tipo,
      descricao
    ) VALUES (idc, v, 'D', d);

    UPDATE users
    SET saldo = saldo - v
      WHERE users.id = idc
      RETURNING saldo, limite INTO saldo_atual, limite_atual;
    COMMIT;
  ELSE
    SELECT -1, -1 INTO saldo_atual, limite_atual;
  END IF;
END;
$$;
