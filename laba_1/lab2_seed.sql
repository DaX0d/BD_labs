BEGIN;

-- 1. Дополнительные пассажиры. Пассажир с паспортом L2 000025 не получит
-- билетов; часть пользователей также останется без email.
INSERT INTO users (last_name, first_name, middle_name, birth_date, passport_number)
SELECT
    'Тестов' || s.n,
    'Пассажир' || s.n,
    CASE WHEN s.n % 3 = 0 THEN NULL ELSE 'Тестович' END,
    DATE '1970-01-01' + (s.n * 367),
    'L2 ' || lpad(s.n::text, 6, '0')
FROM generate_series(6, 25) AS s(n)
WHERE NOT EXISTS (
    SELECT 1
    FROM users u
    WHERE u.passport_number = 'L2 ' || lpad(s.n::text, 6, '0')
);

-- 2. Email есть только у части добавленных пользователей.
INSERT INTO user_emails (user_id, email, is_primary)
SELECT
    u.user_id,
    'passenger' || s.n || '@example.test',
    true
FROM generate_series(6, 20) AS s(n)
JOIN users u
    ON u.passport_number = 'L2 ' || lpad(s.n::text, 6, '0')
WHERE NOT EXISTS (
    SELECT 1
    FROM user_emails e
    WHERE e.email = 'passenger' || s.n || '@example.test'
);

-- 3. Дополнительные рейсы. Даты вылета охватывают сентябрь-декабрь 2026 года.
-- Все шесть аэропортов используются; статусы включают все варианты из CHECK.
INSERT INTO flights (
    flight_number,
    departure_airport_id,
    arrival_airport_id,
    departure_time,
    arrival_time,
    base_price,
    total_seats,
    status
)
SELECT
    'L2' || lpad(s.n::text, 3, '0'),
    ((s.n - 1) % 6) + 1,
    ((s.n + 1) % 6) + 1,
    (
        (DATE '2026-09-01' + ((s.n - 1) * 3) + TIME '07:00')
        + ((s.n % 5) * INTERVAL '1 hour')
    ) AT TIME ZONE 'Europe/Moscow',
    (
        (DATE '2026-09-01' + ((s.n - 1) * 3) + TIME '09:00')
        + ((s.n % 5) * INTERVAL '1 hour')
    ) AT TIME ZONE 'Europe/Moscow',
    5000 + (s.n * 275),
    120 + ((s.n % 5) * 20),
    CASE
        WHEN DATE '2026-09-01' + ((s.n - 1) * 3) < CURRENT_DATE THEN
            CASE
                WHEN s.n % 5 = 0 THEN 'cancelled'
                WHEN s.n % 2 = 0 THEN 'departed'
                ELSE 'arrived'
            END
        ELSE
            CASE
                WHEN s.n % 7 = 0 THEN 'cancelled'
                WHEN s.n % 2 = 0 THEN 'delayed'
                ELSE 'scheduled'
            END
    END
FROM generate_series(1, 36) AS s(n)
WHERE NOT EXISTS (
    SELECT 1
    FROM flights f
    WHERE f.flight_number = 'L2' || lpad(s.n::text, 3, '0')
);

-- 4. 90 билетов: по три билета на каждый из рейсов L2001-L2030.
-- Рейсы L2031-L2035 останутся без билетов, что нужно для LEFT JOIN / NOT EXISTS.
-- Пассажир с паспортом L2 000025 останется без бронирований.
INSERT INTO tickets (
    user_id,
    flight_id,
    seat_number,
    price,
    status,
    booked_at
)
SELECT
    ((s.n - 1) % 24) + 1,
    f.flight_id,
    (((s.n - 1) / 3) + 1)::text
        || CASE (s.n - 1) % 3
            WHEN 0 THEN 'A'
            WHEN 1 THEN 'B'
            ELSE 'C'
           END,
    round(f.base_price * (0.85 + ((s.n % 4) * 0.05)), 2),
    CASE
        WHEN f.status = 'cancelled' THEN 'cancelled'
        WHEN f.status IN ('scheduled', 'delayed') AND s.n % 3 = 0 THEN 'paid'
        WHEN f.status IN ('scheduled', 'delayed') THEN 'booked'
        WHEN s.n % 7 = 0 THEN 'cancelled'
        ELSE 'paid'
    END,
    f.departure_time
        - ((1 + (s.n % 25)) * INTERVAL '1 day')
        + ((s.n % 12) * INTERVAL '1 hour')
FROM generate_series(1, 90) AS s(n)
JOIN flights f
    ON f.flight_number = 'L2' || lpad((((s.n - 1) / 3) + 1)::text, 3, '0')
WHERE NOT EXISTS (
    SELECT 1
    FROM tickets t
    WHERE t.flight_id = f.flight_id
      AND t.seat_number = (
          (((s.n - 1) / 3) + 1)::text
          || CASE (s.n - 1) % 3
              WHEN 0 THEN 'A'
              WHEN 1 THEN 'B'
              ELSE 'C'
             END
      )
);

-- 5. Пограничный допустимый случай: бесплатный билет (price = 0).
-- CHECK ck_tickets_price разрешает нулевую цену. Рейс L2036 специально
-- оставлен без обычных билетов и подходит для демонстрации нулевого значения.
INSERT INTO tickets (user_id, flight_id, seat_number, price, status, booked_at)
SELECT 1, f.flight_id, '1F', 0, 'booked', f.departure_time - INTERVAL '3 days'
FROM flights f
WHERE f.flight_number = 'L2036'
  AND NOT EXISTS (
      SELECT 1
      FROM tickets t
      WHERE t.flight_id = f.flight_id AND t.seat_number = '1F'
  );

COMMIT;

-- Контрольные показатели после наполнения.
SELECT 'users' AS table_name, count(*) AS row_count FROM users
UNION ALL
SELECT 'user_emails', count(*) FROM user_emails
UNION ALL
SELECT 'airports', count(*) FROM airports
UNION ALL
SELECT 'flights', count(*) FROM flights
UNION ALL
SELECT 'tickets', count(*) FROM tickets
ORDER BY table_name;

SELECT
    (SELECT count(*) FROM users)
  + (SELECT count(*) FROM user_emails)
  + (SELECT count(*) FROM airports)
  + (SELECT count(*) FROM flights)
  + (SELECT count(*) FROM tickets) AS total_content_rows,
    (SELECT count(*) FROM tickets) AS tickets_count,
    (SELECT count(DISTINCT date_trunc('month', departure_time)) FROM flights) AS flight_months,
    (SELECT count(DISTINCT status) FROM tickets) AS ticket_statuses,
    (SELECT count(*) FROM flights f
      WHERE NOT EXISTS (SELECT 1 FROM tickets t WHERE t.flight_id = f.flight_id)
    ) AS flights_without_tickets,
    (SELECT count(*) FROM users u
      WHERE NOT EXISTS (SELECT 1 FROM tickets t WHERE t.user_id = u.user_id)
    ) AS users_without_tickets;
