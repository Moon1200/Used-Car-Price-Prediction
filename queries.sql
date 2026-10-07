-- 1. فحص القيم الصفرية وعلاقتها بكون السيارة قابلة للتفاوض
SELECT Negotiable, COUNT(*) AS count_rows,
    SUM(CASE WHEN Price = 0 THEN 1 ELSE 0 END) AS zero_price_count
FROM raw_cars
GROUP BY Negotiable;

-- 2. إنشاء جدول البيانات النظيف (clean_cars) وإزالة التكرارات والأسعار الصفرية
CREATE TABLE clean_cars AS
WITH cleaned AS (
    SELECT DISTINCT
        Make, Type, Year, Origin, Color, Options,
        Engine_Size, Fuel_Type, Gear_Type, Mileage, Region, Price
    FROM raw_cars
    WHERE Price > 0
)
SELECT * FROM cleaned;

-- 3. التحقق من عدد الصفوف في الجدول النظيف
SELECT COUNT(*) FROM clean_cars;

-- 4. إيجاد أعلى 3 سيارات سعراً لكل ماركة باستخدام دوال النوافذ (RANK)
WITH ranked AS (
    SELECT Make, Type, Price, Year,
        RANK() OVER (PARTITION BY Make ORDER BY Price DESC) AS price_rank
    FROM clean_cars
)
SELECT * FROM ranked WHERE price_rank <= 3;

-- 5. حساب المتوسط المتحرك لأسعار السيارات لآخر 3 سنوات (Moving Average)
SELECT Year, COUNT(*) AS car_count, ROUND(AVG(Price),0) AS avg_price,
    AVG(AVG(Price)) OVER (ORDER BY Year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3yr
FROM clean_cars
GROUP BY Year
ORDER BY Year DESC
LIMIT 15;

-- 6. حساب النسبة المئوية لتواجد كل ماركة سيارة داخل كل منطقة جغرافية
SELECT Region, Make, COUNT(*) AS car_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY Region), 2) AS pct_of_region
FROM clean_cars
GROUP BY Region, Make
ORDER BY Region, pct_of_region DESC;

-- 7. تقسيم الأسعار إلى 4 أرباع (Quartiles) لكل ماركة لمعرفة التوزيع السعري
WITH q AS (
    SELECT Make, Type, Price,
        NTILE(4) OVER (PARTITION BY Make ORDER BY Price) AS price_quartile
    FROM clean_cars
)
SELECT Make, price_quartile, COUNT(*) AS count_cars, ROUND(AVG(Price),0) AS avg_price
FROM q
GROUP BY Make, price_quartile
ORDER BY Make, price_quartile;
