INSERT INTO users (last_name, first_name, birth_date, passport_number)
VALUES ('Дубликов', 'Павел', '1990-01-01', '4510 123456');

INSERT INTO user_emails (user_id, email, is_primary)
VALUES (2, 'ivan.ivanov@example.com', false);

INSERT INTO flights (flight_number, departure_airport_id, arrival_airport_id,
                     departure_time, arrival_time, base_price, total_seats)
VALUES ('SU1030', 1, 3, '2026-11-10 08:00:00+03', '2026-11-10 10:50:00+03', 7000.00, 150);

INSERT INTO tickets (user_id, flight_id, seat_number, price)
VALUES (3, 1, '12A', 5500.00);

INSERT INTO user_emails (user_id, email, is_primary)
VALUES (1, 'ivan.second@example.com', true);

INSERT INTO flights (flight_number, departure_airport_id, arrival_airport_id,
                     departure_time, arrival_time, base_price, total_seats)
VALUES ('SU2000', 1, 2, '2026-12-01 12:00:00+03', '2026-12-01 11:00:00+03', 5000.00, 150);

INSERT INTO flights (flight_number, departure_airport_id, arrival_airport_id,
                     departure_time, arrival_time, base_price, total_seats)
VALUES ('SU2001', 1, 1, '2026-12-01 12:00:00+03', '2026-12-01 13:00:00+03', 5000.00, 150);

UPDATE tickets SET price = -100 WHERE ticket_id = 1;

INSERT INTO tickets (user_id, flight_id, seat_number, price, status)
VALUES (3, 2, '8A', 5200.00, 'refunded');

UPDATE flights SET total_seats = 0 WHERE flight_id = 1;
UPDATE flights SET base_price  = 0 WHERE flight_id = 1;

INSERT INTO airports (iata_code, name, city, country)
VALUES ('sv', 'Тестовый', 'Тест', 'Россия');

INSERT INTO users (last_name, first_name, birth_date, passport_number)
VALUES ('Будущев', 'Иван', CURRENT_DATE + 1, '9999 999999');

INSERT INTO user_emails (user_id, email) VALUES (2, 'not-an-email');

INSERT INTO users (last_name, birth_date, passport_number)
VALUES ('Безымянов', '1990-01-01', '1234 567890');

INSERT INTO tickets (user_id, flight_id, seat_number, price)
VALUES (1, 999, '1A', 1000.00);

INSERT INTO user_emails (user_id, email) VALUES (999, 'ghost@example.com');

DELETE FROM users WHERE user_id = 1;

DELETE FROM flights WHERE flight_id = 1;

DELETE FROM airports WHERE airport_id = 1;

BEGIN;
SELECT count(*) AS emails_before FROM user_emails WHERE user_id = 5;
DELETE FROM users WHERE user_id = 5;
SELECT count(*) AS emails_after  FROM user_emails WHERE user_id = 5;
ROLLBACK;
