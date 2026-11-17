/* 3.1. Рейсы, базовая цена которых выше среднего значения
   для рейсов с тем же аэропортом отправления.
   Подзапрос в FROM сначала вычисляет среднюю цену по каждой группе. */
SELECT
    f.flight_id,
    f.flight_number,
    dep.city AS departure_city,
    arr.city AS arrival_city,
    f.base_price,
    avg_by_origin.avg_base_price
FROM flights f
JOIN airports dep ON dep.airport_id = f.departure_airport_id
JOIN airports arr ON arr.airport_id = f.arrival_airport_id
JOIN (
    SELECT
        departure_airport_id,
        avg(base_price) AS avg_base_price
    FROM flights
    GROUP BY departure_airport_id
) AS avg_by_origin
    ON avg_by_origin.departure_airport_id = f.departure_airport_id
WHERE f.base_price > avg_by_origin.avg_base_price
ORDER BY dep.city, f.base_price DESC;

/* 3.2. EXISTS: пассажиры, у которых есть хотя бы один оплаченный билет
   на рейс, прибывающий в аэропорт Стамбула (IST). */
SELECT
    u.user_id,
    u.last_name,
    u.first_name
FROM users u
WHERE EXISTS (
    SELECT 1
    FROM tickets t
    JOIN flights f ON f.flight_id = t.flight_id
    JOIN airports a ON a.airport_id = f.arrival_airport_id
    WHERE t.user_id = u.user_id
      AND t.status = 'paid'
      AND a.iata_code = 'IST'
)
ORDER BY u.user_id;

/* 3.3. NOT EXISTS: зарегистрированные пассажиры, которые ни разу
   не оформляли билет. Это означает отсутствие бронирований в системе. */
SELECT
    u.user_id,
    u.last_name,
    u.first_name,
    u.passport_number
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM tickets t
    WHERE t.user_id = u.user_id
)
ORDER BY u.user_id;

/* 3.4. Коррелированный подзапрос: для каждого рейса отдельно вычисляется
   количество активных билетов и процент занятости салона.
   Внутренние запросы связаны с текущей строкой по f.flight_id;
   во втором запросе также используется f.total_seats. */
SELECT
    f.flight_id,
    f.flight_number,
    f.total_seats,
    (
        SELECT count(*)
        FROM tickets t
        WHERE t.flight_id = f.flight_id
          AND t.status IN ('booked', 'paid')
    ) AS active_ticket_count,
    coalesce(
        (
            SELECT round(
                100.0 * count(t.ticket_id)::numeric / nullif(f.total_seats, 0),
                2
            )
            FROM tickets t
            WHERE t.flight_id = f.flight_id
              AND t.status IN ('booked', 'paid')
        ),
        0
    ) AS occupancy_percent
FROM flights f
ORDER BY f.departure_time, f.flight_id;
