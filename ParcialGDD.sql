select 
    year(f1.fact_fecha), 
    clie_razon_social, 
    p1.prod_familia,
    count(distinct item_producto)
from Factura f1
join item_factura on f1.fact_tipo = item_tipo and f1.fact_sucursal = item_sucursal and f1.fact_numero = item_numero
join Producto p1 on p1.prod_codigo = item_producto
join Cliente on f1.fact_cliente = clie_codigo
group by year(f1.fact_fecha), clie_razon_social, p1.prod_familia, clie_codigo
having clie_codigo in 
    (
    select top 1 fact_cliente from Factura f2
    join item_factura on f2.fact_tipo = item_tipo and f2.fact_sucursal = item_sucursal and f2.fact_numero = item_numero
    join producto on prod_codigo = item_producto and prod_familia = p1.prod_familia
    where year(f2.fact_fecha) = year(f1.fact_fecha)
    group by fact_cliente
    order by count(distinct item_producto)
    )
order by year(f1.fact_fecha), (select count(distinct prod_codigo) from Producto where prod_familia = p1.prod_familia)