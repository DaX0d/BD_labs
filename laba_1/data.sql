INSERT INTO users (user_id, last_name, first_name, middle_name, birth_date, passport_number) VALUES
    (1, 'Иванов', 'Иван', 'Иванович', '1998-05-14', '4510 123456'),
    (2, 'Петрова', 'Анна', 'Сергеевна', '2001-09-02', '4511 654321'),
    (3, 'Смирнов', 'Дмитрий', NULL, '1985-12-30', '4009 111222'),
    (4, 'Кузнецова', 'Елена', 'Викторовна', '1992-03-18', '4012 333444'),
    (5, 'Соколов', 'Артём', 'Олегович', '2003-07-07', '4515 555666');

INSERT INTO user_emails (email_id, user_id, email, is_primary) VALUES
    (1, 1, 'ivan.ivanov@example.com', true),
    (2, 1, 'ivanov.work@example.com', false),
    (3, 2, 'anna.petrova@example.com', true),
    (4, 3, 'smirnov.d@example.com', true),
    (5, 4, 'elena.kuznetsova@example.com', true),
    (6, 4, 'kuznetsova.e@example.org', false),
    (7, 5, 'artem.sokolov@example.com', true);

INSERT INTO airports (airport_id, iata_code, name, city, country) VALUES
    (1, 'SVO', 'Шереметьево', 'Москва', 'Россия'),
    (2, 'LED', 'Пулково', 'Санкт-Петербург', 'Россия'),
    (3, 'AER', 'Сочи', 'Сочи', 'Россия'),
    (4, 'KZN', 'Казань', 'Казань', 'Россия'),
    (5, 'OVB', 'Толмачёво', 'Новосибирск', 'Россия'),
    (6, 'IST', 'Стамбул', 'Стамбул', 'Турция');

INSERT INTO flights (flight_id, flight_number, departure_airport_id, arrival_airport_id,
                     departure_time, arrival_time, base_price, total_seats, status) VALUES
    (1, 'SU1030', 1, 2, '2026-11-10 08:00:00+03', '2026-11-10 09:30:00+03', 5500.00, 180, 'scheduled'),
    (2, 'SU1031', 2, 1, '2026-11-10 19:00:00+03', '2026-11-10 20:25:00+03', 5200.00, 180, 'scheduled'),
    (3, 'S7201', 1, 3, '2026-11-12 06:30:00+03', '2026-11-12 09:15:00+03', 8900.00, 220, 'scheduled'),
    (4, 'DP405', 4, 5, '2026-11-14 09:00:00+03', '2026-11-14 15:30:00+07', 7200.00, 160, 'delayed'),
    (5, 'TK418', 1, 6, '2026-11-15 10:00:00+03', '2026-11-15 13:10:00+03', 18500.00, 300, 'scheduled'),
    (6, 'S7302', 5, 1, '2026-11-20 03:00:00+07', '2026-11-20 03:30:00+03', 9900.00, 200, 'scheduled');

INSERT INTO tickets (ticket_id, user_id, flight_id, seat_number, price, status, booked_at) VALUES
    (1, 1, 1, '12A', 5500.00, 'paid', '2026-10-01 10:15:00+03'),
    (2, 2, 1, '12B', 5500.00, 'paid', '2026-10-01 10:17:00+03'),
    (3, 1, 2, '7C', 5200.00, 'booked', '2026-10-02 12:00:00+03'),
    (4, 3, 3, '21D', 8900.00, 'paid', '2026-10-03 09:30:00+03'),
    (5, 4, 3, '21E', 8450.00, 'paid', '2026-09-28 18:45:00+03'),
    (6, 4, 3, '21F', 8450.00, 'cancelled', '2026-09-28 18:50:00+03'),
    (7, 3, 5, '3A', 18500.00, 'paid', '2026-10-05 14:20:00+03'),
    (8, 2, 4, '15B', 6900.00, 'booked', '2026-10-06 16:05:00+03'),
    (9, 4, 6, '10A', 9900.00, 'paid', '2026-10-07 11:40:00+03'),
    (10, 1, 5, '3B', 18500.00, 'booked', '2026-10-08 09:00:00+03');

SELECT setval(pg_get_serial_sequence('users', 'user_id'), (SELECT max(user_id) FROM users));
SELECT setval(pg_get_serial_sequence('user_emails', 'email_id'), (SELECT max(email_id) FROM user_emails));
SELECT setval(pg_get_serial_sequence('airports', 'airport_id'), (SELECT max(airport_id) FROM airports));
SELECT setval(pg_get_serial_sequence('flights', 'flight_id'), (SELECT max(flight_id) FROM flights));
SELECT setval(pg_get_serial_sequence('tickets', 'ticket_id'), (SELECT max(ticket_id) FROM tickets));
