/* 2.1.1. Подробная информация о билетах, пассажирах, рейсах,
   аэропортах отправления/прибытия и основном email пассажира. */
SELECT
    t.ticket_id,
    u.user_id,
    u.last_name,
    u.first_name,
    ue.email AS primary_email,
    t.seat_number,
    t.status AS ticket_status,
    t.price AS ticket_price,
    f.flight_number,
    f.status AS flight_status,
    f.departure_time,
    dep.iata_code AS departure_iata,
    dep.city AS departure_city,
    arr.iata_code AS arrival_iata,
    arr.city AS arrival_city
FROM tickets t
JOIN users u ON u.user_id = t.user_id
JOIN flights f ON f.flight_id = t.flight_id
JOIN airports dep ON dep.airport_id = f.departure_airport_id
JOIN airports arr ON arr.airport_id = f.arrival_airport_id
LEFT JOIN user_emails ue
    ON ue.user_id = u.user_id AND ue.is_primary
ORDER BY f.departure_time, t.ticket_id;

/* 2.1.2. Пассажиры без единого билета.
   LEFT JOIN сохраняет пассажиров без связанных записей.
   Дополнительно присоединены email и flights; COUNT(DISTINCT) не допускает
   размножения строк из-за нескольких email у одного пользователя. */
SELECT
    u.user_id,
    u.last_name,
    u.first_name,
    count(DISTINCT ue.email_id) AS email_count,
    count(DISTINCT t.ticket_id) AS ticket_count,
    count(DISTINCT f.flight_id) AS linked_flight_count
FROM users u
LEFT JOIN user_emails ue ON ue.user_id = u.user_id
LEFT JOIN tickets t ON t.user_id = u.user_id
LEFT JOIN flights f ON f.flight_id = t.flight_id
GROUP BY u.user_id, u.last_name, u.first_name
HAVING count(DISTINCT t.ticket_id) = 0
ORDER BY u.user_id;

/* 2.1.3. Билеты на международные рейсы из России в Турцию:
   билет оплачен или забронирован, цена не ниже 7000, рейс не отменен. */
SELECT
    t.ticket_id,
    u.last_name,
    u.first_name,
    ue.email AS primary_email,
    f.flight_number,
    dep.city AS departure_city,
    arr.city AS arrival_city,
    t.seat_number,
    t.price,
    t.status AS ticket_status,
    f.status AS flight_status
FROM tickets t
JOIN users u ON u.user_id = t.user_id
JOIN flights f ON f.flight_id = t.flight_id
JOIN airports dep ON dep.airport_id = f.departure_airport_id
JOIN airports arr ON arr.airport_id = f.arrival_airport_id
LEFT JOIN user_emails ue
    ON ue.user_id = u.user_id AND ue.is_primary
WHERE t.status IN ('paid', 'booked')
  AND t.price >= 7000
  AND f.status <> 'cancelled'
  AND dep.country = 'Россия'
  AND arr.country = 'Турция'
ORDER BY f.departure_time, t.price DESC;

/* 2.2.1. Количественные и денежные показатели по маршрутам и месяцам.
   COUNT, SUM, AVG, MIN и MAX применены к разным показателям.
   Отмененные билеты учитываются отдельно, а выручка считается по paid. */
SELECT
    date_trunc('month', f.departure_time)::date AS departure_month,
    dep.city AS departure_city,
    arr.city AS arrival_city,
    count(t.ticket_id) AS all_tickets,
    count(t.ticket_id) FILTER (WHERE t.status = 'paid') AS paid_tickets,
    count(t.ticket_id) FILTER (WHERE t.status = 'cancelled') AS cancelled_tickets,
    coalesce(sum(t.price) FILTER (WHERE t.status = 'paid'), 0)::numeric(14,2) AS paid_revenue,
    round(avg(t.price) FILTER (WHERE t.status = 'paid'), 2) AS avg_paid_ticket_price,
    min(t.price) FILTER (WHERE t.status = 'paid') AS min_paid_ticket_price,
    max(t.price) FILTER (WHERE t.status = 'paid') AS max_paid_ticket_price
FROM flights f
JOIN airports dep ON dep.airport_id = f.departure_airport_id
JOIN airports arr ON arr.airport_id = f.arrival_airport_id
LEFT JOIN tickets t ON t.flight_id = f.flight_id
GROUP BY date_trunc('month', f.departure_time)::date, dep.city, arr.city
ORDER BY departure_month, departure_city, arrival_city;

/* 2.2.2. Пассажиры с несколькими активными билетами и существенной
   суммой оплаченных билетов. HAVING фильтрует уже сгруппированные данные. */
SELECT
    u.user_id,
    u.last_name,
    u.first_name,
    count(t.ticket_id) FILTER (WHERE t.status IN ('booked', 'paid')) AS active_ticket_count,
    coalesce(sum(t.price) FILTER (WHERE t.status = 'paid'), 0)::numeric(14,2) AS paid_total,
    round(avg(t.price) FILTER (WHERE t.status = 'paid'), 2) AS avg_paid_ticket_price
FROM users u
LEFT JOIN tickets t ON t.user_id = u.user_id
GROUP BY u.user_id, u.last_name, u.first_name
HAVING count(t.ticket_id) FILTER (WHERE t.status IN ('booked', 'paid')) >= 2
   AND coalesce(sum(t.price) FILTER (WHERE t.status = 'paid'), 0) >= 10000
ORDER BY paid_total DESC, u.user_id;

/* 2.2.3. Сравнение показателей между календарными месяцами.
   LEFT JOIN позволяет показать месяцы с рейсами, у которых нет билетов. */
SELECT
    date_trunc('month', f.departure_time)::date AS departure_month,
    count(DISTINCT f.flight_id) AS flights_count,
    count(t.ticket_id) AS tickets_count,
    count(t.ticket_id) FILTER (WHERE t.status = 'paid') AS paid_tickets,
    count(t.ticket_id) FILTER (WHERE t.status = 'booked') AS booked_tickets,
    count(t.ticket_id) FILTER (WHERE t.status = 'cancelled') AS cancelled_tickets,
    coalesce(sum(t.price) FILTER (WHERE t.status = 'paid'), 0)::numeric(14,2) AS paid_revenue,
    round(avg(t.price) FILTER (WHERE t.status = 'paid'), 2) AS avg_paid_ticket_price
FROM flights f
LEFT JOIN tickets t ON t.flight_id = f.flight_id
GROUP BY date_trunc('month', f.departure_time)::date
ORDER BY departure_month;
