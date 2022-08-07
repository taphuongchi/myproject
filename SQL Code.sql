/* Câu 1: Từ bảng DimProduct, DimSalesTerritory và FactInternetSales, hãy truy vấn ra các thông tin sau của các đơn hàng được đặt trong
năm 2013 và 2014:
- SalesOrderNumber
- SalesOrderLineNumber
- ProductKey
- EnglishProductName
- SalesTerritoryCountry
- SalesAmount
- OrderQuantity
*/

Select 
	FIS.SalesOrderNumber
	, FIS.SalesOrderLineNumber
	, FIS.SalesAmount
	, FIS.OrderQuantity
	, Product.ProductKey
	, Product.EnglishProductName
	, DST.SalesTerritoryCountry
From FactInternetSales as FIS
	JOIN DimProduct as Product		ON Product.ProductKey= FIS.ProductKey
	JOIN DimSalesTerritory as DST	ON DST.SalesTerritoryKey= FIS.SalesTerritoryKey
WHERE YEAR(FIS.OrderDate) IN ('2013','2014')

/* Câu 2: Từ bảng DimProduct, DimSalesTerritory và FactInternetSales, tính tổng doanh thu (đặt tên là InternetTotalSales) và số đơn hàng
(đặt tên là NumberofOrders) của từng sản phẩm theo mỗi quốc gia từ bảng DimSalesTerritory. Kết quả trả về gồm có các thông tin
sau:
- SalesTerritoryCountry
- ProductKey
- EnglishProductName
- InternetTotalSales
- NumberofOrders
*/

 Select 
	 DST.SalesTerritoryCountry
	, Product.ProductKey
	, Product.EnglishProductName
	, Sum(FIS.SalesAmount) as InternetTotalSales
	, COUNT (FIS.SalesOrderNumber) as NumberOfOrders
From FactInternetSales as FIS
	JOIN DimProduct as Product		ON Product.ProductKey= FIS.ProductKey
	JOIN DimSalesTerritory as DST	ON DST.SalesTerritoryKey= FIS.SalesTerritoryKey
GROUP BY Product.EnglishProductName, DST.SalesTerritoryCountry, Product.ProductKey
ORDER BY Product.ProductKey, NumberOfOrders

/* Câu 3: Từ bảng DimProduct, DimSalesTerritory và FactInternetSales, hãy tính toán % tỷ trọng doanh thu của từng sản phẩm (đặt tên là
PercentofTotaInCountry) trong Tổng doanh thu của mỗi quốc gia. Kết quả trả về gồm có các thông tin sau:
- SalesTerritoryCountry
- ProductKey
- EnglishProductName
- InternetTotalSales
- PercentofTotaInCountry (định dạng %)
*/

Select 
	GR2.SalesTerritoryCountry
	, ProductKey
	, EnglishProductName
	, InternetTotalSales
	, Format(GR1.InternetTotalSales/ GR2.TotalSales_Country, 'p') as PercentOfTotalnCountry
From 
	(Select 
		 DST.SalesTerritoryCountry
		, Product.ProductKey
		, Product.EnglishProductName
		, Sum(FIS.SalesAmount) as InternetTotalSales
	From FactInternetSales as FIS
		JOIN DimProduct as Product		ON Product.ProductKey= FIS.ProductKey
		JOIN DimSalesTerritory as DST	ON DST.SalesTerritoryKey= FIS.SalesTerritoryKey
	GROUP BY Product.EnglishProductName, DST.SalesTerritoryCountry, Product.ProductKey) as GR1
JOIN 
	(Select 
		Territory.SalesTerritoryCountry
		,sum(InternetSales.SalesAmount)  as TotalSales_Country
	From FactInternetSales as InternetSales 
		JOIN DimSalesTerritory as Territory ON Territory.SalesTerritoryKey= InternetSales.SalesTerritoryKey
	GROUP BY Territory.SalesTerritoryCountry) as GR2  
ON GR1.SalesTerritoryCountry= GR2.SalesTerritoryCountry
ORDER BY GR2.SalesTerritoryCountry, ProductKey

/* Câu 4: Từ bảng FactInternetSales, và DimCustomer, hãy truy vấn ra danh sách top 3 khách hàng có tổng doanh thu tháng (đặt tên là
CustomerMonthAmount) cao nhất trong hệ thống theo mỗi tháng.
Kết quả trả về gồm có các thông tin sau:
- OrderYear
- OrderMonth
- CustomerKey
- CustomerFullName(kết hợp từ FirstName, MiddleName, LastName)
- CustomerMonthAmount
*/

Select
	temp.OrderYear
	, temp.OrderMonth
	, temp.CustomerMonthAmount
	, temp.SalesAmountRankCustomer
	, temp.CustomerFullName
	, temp.CustomerKey
From
	(Select
		YEAR(FIS.OrderDate) as OrderYear
		, MONTH(FIS.OrderDate) as OrderMonth
		, FIS.CustomerKey
		, Customer.FirstName + ' ' +  Isnull(Customer.MiddleName,'')+ ' ' + Customer.LastName as CustomerFullName
		, sum(FIS.SalesAmount) as CustomerMonthAmount
		, ROW_NUMBER() OVER
			(PARTITION BY Year(FIS.OrderDate), MONTH(FIS.OrderDate)
				ORDER BY sum(FIS.SalesAmount) DESC ) as  SalesAmountRankCustomer
	From FactInternetSales as FIS
	JOIN DimCustomer as Customer ON Customer.CustomerKey= FIS.CustomerKey
GROUP BY YEAR(FIS.OrderDate), MONTH(FIS.OrderDate),  Customer.FirstName + ' ' +  Isnull(Customer.MiddleName,'')+ ' ' + Customer.LastName, FIS.CustomerKey) as temp
WHERE temp.SalesAmountRankCustomer<=3
ORDER BY Temp.OrderYear, temp.OrderMonth, temp.SalesAmountRankCustomer, temp.CustomerKey

/* Câu 5: Từ bảng FactInternetSales, tính toán tổng doanh thu theo từng tháng (đặt tên là InternetMonthAmount). Kết quả trả về gồm có các
thông tin sau:
- OrderYear
- OrderMonth
- InternetMonthAmount
*/

Select
	YEAR(FIS.OrderDate) as OrderYear
	, MONTH(FIS.OrderDate) as OrderMonth
	, sum(FIS.SalesAmount) as InternetMonthAmount
From FactInternetSales as FIS
GROUP BY YEAR(FIS.OrderDate), MONTH(FIS.OrderDate)
ORDER BY YEAR(FIS.OrderDate), MONTH(FIS.OrderDate)

/* Câu 6: Từ bảng FactInternetSales hãy tính toán % tăng trưởng doanh thu (đặt tên là PercentSalesGrowth) so với cùng kỳ năm trước (ví dụ:
Tháng 11 năm 2012 thì so sánh với tháng 11 năm 2011). Kết quả trả về gồm có các thông tin sau:
- OrderYear
- OrderMonth
- InternetMonthAmount
- InternetMonthAmount_LastYear
- PercentSalesGrowth
*/

With SalesbyMonth as 
	(Select 
		YEAR(FIS.OrderDate) as Order_Year
		, MONTH(FIS.OrderDate) as Order_Month
		, sum(FIS.SalesAmount) as Present_SalesAmount
		From FactInternetSales as FIS
	GROUP BY YEAR(FIS.OrderDate), MONTH(FIS.OrderDate))
Select
	SM.Order_Year
	, SM.Order_Month
	, SM.Present_SalesAmount as Present_Revenue
	, LM.Present_SalesAmount as Last_Revenue
	, FORMAT((SM.Present_SalesAmount- LM.Present_SalesAmount)/LM.Present_SalesAmount , 'p') as PercentSalesGrowth
From SalesbyMonth as SM
	LEFT JOIN SalesbyMonth as LM 
ON LM.Order_Year = SM.Order_Year - 1 AND LM.Order_Month= SM.Order_Month
ORDER BY Order_Year, Order_Month
