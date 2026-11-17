/*
Вопрос: какие направления в каждом месяце дают наибольшую
оплаченную выручку, сколько билетов бронируют/оплачивают/отменяют и какова
доля отмен?
Период отчета: сентябрь-декабрь 2026 года.
*/

WITH ticket_facts AS (
    -- Этап 1. Исходные данные: рейсы, города маршрута и связанные билеты.
    -- LEFT JOIN сохраняет рейсы, на которые еще никто не купил билет.
    SELECT
        date_trunc('month', f.departure_time)::date AS departure_month,
        f.flight_id,
        dep.city || ' -> ' || arr.city AS route,
        t.ticket_id,
        t.status AS ticket_status,
        t.price AS ticket_price
    FROM flights f
    JOIN airports dep ON dep.airport_id = f.departure_airport_id
    JOIN airports arr ON arr.airport_id = f.arrival_airport_id
    LEFT JOIN tickets t ON t.flight_id = f.flight_id
    WHERE f.departure_time >= TIMESTAMPTZ '2026-09-01 00:00:00+03'
      AND f.departure_time <  TIMESTAMPTZ '2027-01-01 00:00:00+03'
),
route_month_metrics AS (
    -- Этапы 2-3. Промежуточные показатели и агрегация по месяцу и маршруту.
    SELECT
        departure_month,
        route,
        count(DISTINCT flight_id) AS flights_count,
        count(ticket_id) AS all_tickets,
        count(ticket_id) FILTER (WHERE ticket_status = 'paid') AS paid_tickets,
        count(ticket_id) FILTER (WHERE ticket_status = 'booked') AS booked_tickets,
        count(ticket_id) FILTER (WHERE ticket_status = 'cancelled') AS cancelled_tickets,
        coalesce(
            sum(ticket_price) FILTER (WHERE ticket_status = 'paid'),
            0
        )::numeric(14,2) AS paid_revenue,
        round(avg(ticket_price) FILTER (WHERE ticket_status = 'paid'), 2)
            AS avg_paid_ticket_price,
        round(
            100.0
            * count(ticket_id) FILTER (WHERE ticket_status = 'cancelled')
            / nullif(count(ticket_id), 0),
            2
        ) AS cancellation_rate_percent
    FROM ticket_facts
    GROUP BY departure_month, route
),
ranked_routes AS (
    -- Этап 4. Ранжирование направлений внутри каждого месяца по выручке.
    SELECT
        *,
        dense_rank() OVER (
            PARTITION BY departure_month
            ORDER BY paid_revenue DESC, paid_tickets DESC
        ) AS revenue_rank
    FROM route_month_metrics
)
-- Итоговый отчет: лидеры месяца идут первыми; направления без продаж
-- тоже остаются в отчете с нулевой выручкой.
SELECT
    departure_month,
    revenue_rank,
    route,
    flights_count,
    all_tickets,
    paid_tickets,
    booked_tickets,
    cancelled_tickets,
    paid_revenue,
    avg_paid_ticket_price,
    cancellation_rate_percent
FROM ranked_routes
ORDER BY departure_month, revenue_rank, route;
