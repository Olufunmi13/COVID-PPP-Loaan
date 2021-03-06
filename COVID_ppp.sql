---Data cleaning--
SELECT *
  FROM [covid_ppp].[dbo].['table_of_size_standards_all$']
  WHERE NAICS_Codes is NULL


 ---Removing NULLS from standard table
 DELETE FROM [covid_ppp].[dbo].['table_of_size_standards_all$']
 WHERE NAICS_Industry_Description is NULL


SELECT *
INTO new_table_standards
FROM(

  SELECT 
		NAICS_Industry_Description,
		case when NAICS_Industry_Description like '%–%' then substring (NAICS_Industry_Description, 8, 2)end code,
		iif(NAICS_Industry_Description like '%–%',ltrim(substring ([NAICS_Industry_Description],CHARINDEX('–',[NAICS_Industry_Description])+1, LEN([NAICS_Industry_Description]))),'')sector
  FROM [covid_ppp].[dbo].['table_of_size_standards_all$']
  WHERE NAICS_Industry_Description LIKE '%Sector%'
)main
WHERE 
	Sector !=''

---UPDATE NEW TABLE---
SELECT *
  FROM [covid_ppp].[dbo].[new_table_standards]

  insert into [dbo].[new_table_standards]
  values 
  ('Sector 31 – 33 – Manufacturing',32,'Manufacturing'),
  ('Sector 31 – 33 – Manufacturing',33,'Manufacturing'),
  ('Sector 44 - 45 – Retail Trade', 45, 'Retail Trade'),
  ('Sector 48 - 49 – Transportation and Warehousing',49,'Transportation and Warehousing')

  update [dbo].[new_table_standards]
  set sector = 'Manufacturing'
  where code = 31

  SELECT *
  FROM [covid_ppp].[dbo].[new_table_standards]
  ORDER BY code

  ---DATA EXPLORATION---
select *
from [covid_ppp].[dbo].[ppp_over_150k]

---verification of data type---
SELECT
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH AS MAX_LENGTH, 
    CHARACTER_OCTET_LENGTH AS OCTET_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'ppp_over_150k'
AND COLUMN_NAME = 'InitialApprovalAmount';


---Summary of initial loan approval amount for 2020 and 2021
select
	count (distinct OriginatingLender)Originatinglender,
	year(DateApproved) year,
	SUM(CAST(InitialApprovalAmount AS decimal)) totalamount, --(875705554)
	count(LoanNumber) no_of_approved_loans, --(807)
	AVG(CAST(InitialApprovalAmount AS decimal))average --(1085136.993804)
from [covid_ppp].[dbo].[ppp_over_150k]
where 
	year(DateApproved) = 2020 
group by 
	year(DateApproved) 

union

select
	count (distinct OriginatingLender)Originatinglender,
	year(DateApproved),
	SUM(CAST(InitialApprovalAmount AS decimal)) totalamount, --(875705554)
	count(LoanNumber) no_of_approved_loans, --(807)
	AVG(CAST(InitialApprovalAmount AS decimal))average --(1085136.993804)
from [covid_ppp].[dbo].[ppp_over_150k]
where 
	year(DateApproved) = 2021
group by 
	year(DateApproved)

	
---Summary of current loan approval amount for 2020 and 2021
select
	year(DateApproved) year,
	SUM(CAST(CurrentApprovalAmount AS decimal)) totalamount, --(875705554)
	count(LoanNumber) no_of_approved_loans, --(807)
	AVG(CAST(CurrentApprovalAmount AS decimal))average --(1085136.993804)
from [covid_ppp].[dbo].[ppp_over_150k]
where 
	year(DateApproved) = 2020 
group by 
	year(DateApproved) 

union

select
	year(DateApproved),
	SUM(CAST(CurrentApprovalAmount AS decimal)) totalamount, --(875705554)
	count(LoanNumber) no_of_approved_loans, --(807)
	AVG(CAST(CurrentApprovalAmount AS decimal))average --(1085136.993804)
from [covid_ppp].[dbo].[ppp_over_150k]
where 
	year(DateApproved) = 2021
group by 
	year(DateApproved)

---Top 15 highest Originating lender cities 
select top 15
	originatingLenderCity,
	Max(LoanNumber)no_of_loan_approved
from [covid_ppp].[dbo].[ppp_over_150k]
group by OriginatingLenderCity
order by 2 desc

---Top 10 Originating lenders by loan count and average
select top 10
	OriginatingLender,
	count(LoanNumber) no_of_approved_loans,
	SUM(CAST(InitialApprovalAmount AS decimal)) totalamount, --(875705554)
	AVG(CAST(InitialApprovalAmount AS decimal))average --(1085136.993804)
from [covid_ppp].[dbo].[ppp_over_150k]
where 
	year(DateApproved) = 2020
group by 
	OriginatingLender
order by 2 desc

---What is the business type with highest number of loan approved
select 
	distinct (BusinessType),
	Max(LoanNumber)
from [covid_ppp].[dbo].[ppp_over_150k]
group by BusinessType
order by 2 desc

---What percentage of the approved loan have been fully forgiven in 2020
select
	count(LoanNumber) No_of_approved_loan,
	sum(CAST(CurrentApprovalAmount AS decimal)) Current_Approval_Amount,
	avg(CAST(CurrentApprovalAmount AS decimal))Averge_Approval_Amount,
	sum(try_CONVERT (decimal, ForgivenessAmount)) Amount_forgiven,
	sum(try_CONVERT (decimal, ForgivenessAmount))/sum(CAST(CurrentApprovalAmount AS decimal))*100 percent_forgiven
from [covid_ppp].[dbo].[ppp_over_150k]
where year(DateApproved) =2020
order by 3 desc


---What percentage of the approved loan have been fully forgiven in 2021
;with new as
(
select
	b.sector,
	count(LoanNumber) no_of_approved_loans,
	SUM(CAST(InitialApprovalAmount AS decimal)) totalamount, 
	AVG(CAST(InitialApprovalAmount AS decimal))average
from [covid_ppp].[dbo].[ppp_over_150k]a
	inner join [dbo].[new_table_standards] b
	ON left(a.NAICSCode,2) = b.code
where 
	year(DateApproved) = 2020 
group by 
	b.sector
--order by 3 desc
)
select sector,no_of_approved_loans,totalamount,average,
totalamount/sum(totalamount)OVER()*100 percent_of_amount
from new
group by new.sector,new.no_of_approved_loans,new.totalamount,new.average
order by totalamount desc	

---What is the industry sector with the highest approved loan in 2021
;with new as
(
select
	b.sector,
	count(LoanNumber) no_of_approved_loans,
	SUM(CAST(InitialApprovalAmount AS decimal)) totalamount, 
	AVG(CAST(InitialApprovalAmount AS decimal))average
from [covid_ppp].[dbo].[ppp_over_150k]a
	inner join [dbo].[new_table_standards] b
	ON left(a.NAICSCode,2) = b.code
where 
	year(DateApproved) = 2021 
group by 
	b.sector
--order by 3 desc
)
select sector,no_of_approved_loans,totalamount,average,
totalamount/sum(totalamount)OVER()*100 percent_of_amount
from new
group by new.sector,new.no_of_approved_loans,new.totalamount,new.average
order by totalamount desc

