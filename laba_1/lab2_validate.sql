SELECT
    (SELECT count(*) FROM users)
  + (SELECT count(*) FROM user_emails)
  + (SELECT count(*) FROM airports)
  + (SELECT count(*) FROM flights)
  + (SELECT count(*) FROM tickets) AS total_content_rows,
    (SELECT count(*) FROM tickets) AS tickets_count,
    (SELECT count(DISTINCT date_trunc('month', departure_time)) FROM flights) AS flight_months,
    (SELECT count(DISTINCT status) FROM tickets) AS ticket_statuses,
    (SELECT count(*) FROM users u
      WHERE NOT EXISTS (SELECT 1 FROM tickets t WHERE t.user_id = u.user_id)
    ) AS users_without_tickets,
    (SELECT count(*) FROM flights f
      WHERE NOT EXISTS (SELECT 1 FROM tickets t WHERE t.flight_id = f.flight_id)
    ) AS flights_without_tickets;

-- Распределение статусов билетов: должны присутствовать booked, paid, cancelled.
SELECT status, count(*) AS tickets_count
FROM tickets
GROUP BY status
ORDER BY status;

-- Количество рейсов по месяцам вылета.
SELECT date_trunc('month', departure_time)::date AS departure_month,
       count(*) AS flights_count
FROM flights
GROUP BY date_trunc('month', departure_time)::date
ORDER BY departure_month;
