BEGIN;

-- 1. Добавление новой сущности (пассажира) и связанных записей (email и билет).
INSERT INTO users (
    last_name, first_name, middle_name, birth_date, passport_number
)
VALUES (
    'Лабораторный', 'Пассажир', NULL, DATE '1998-02-03', 'L2 999999'
)
ON CONFLICT (passport_number) DO NOTHING;

INSERT INTO user_emails (user_id, email, is_primary)
SELECT user_id, 'lab2.passenger@example.test', true
FROM users
WHERE passport_number = 'L2 999999'
ON CONFLICT (email) DO NOTHING;

-- L2034 - тестовый рейс без билетов; место 99F допустимо по формату.
INSERT INTO tickets (user_id, flight_id, seat_number, price, status)
SELECT u.user_id, f.flight_id, '99F', f.base_price, 'booked'
FROM users u
JOIN flights f ON f.flight_number = 'L2034'
WHERE u.passport_number = 'L2 999999'
  AND NOT EXISTS (
      SELECT 1
      FROM tickets t
      WHERE t.flight_id = f.flight_id AND t.seat_number = '99F'
  );

-- 2. Изменение состояния существующей операции: билет № 3 переводится в paid.
UPDATE tickets
SET status = 'paid'
WHERE ticket_id = 3
  AND status = 'booked'
RETURNING ticket_id, status;

-- 3. Массовое изменение по содержательному условию:
-- просроченные по времени вылета рейсы, оставшиеся scheduled/delayed,
-- переводятся в departed.
UPDATE flights
SET status = 'departed'
WHERE status IN ('scheduled', 'delayed')
  AND departure_time < now()
RETURNING flight_id, flight_number, departure_time, status;

-- 4. Удаление с учетом FK ON DELETE RESTRICT для tickets.user_id:
-- сначала удаляем билет тестового пассажира, затем самого пассажира.
-- Email удалится автоматически благодаря ON DELETE CASCADE.
DELETE FROM tickets
WHERE user_id = (
    SELECT user_id FROM users WHERE passport_number = 'L2 999999'
)
RETURNING ticket_id, user_id, flight_id;

DELETE FROM users
WHERE passport_number = 'L2 999999'
RETURNING user_id, passport_number;

-- Состояние внутри транзакции непосредственно перед откатом.
SELECT
    (SELECT count(*) FROM users WHERE passport_number = 'L2 999999') AS temp_user_before_rollback,
    (SELECT status FROM tickets WHERE ticket_id = 3) AS ticket_3_status_before_rollback;

-- 5. Отмена INSERT / UPDATE / DELETE выше.
ROLLBACK;

-- Контроль: пассажир не сохранен, билет №3 снова имеет исходный статус booked.
SELECT
    (SELECT count(*) FROM users WHERE passport_number = 'L2 999999') AS temp_user_after_rollback,
    (SELECT status FROM tickets WHERE ticket_id = 3) AS ticket_3_status_after_rollback;
