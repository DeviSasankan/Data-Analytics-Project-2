# Discount Sales Case Study

## Overview
This project analyzes a fictional 6-month retail sales dataset (Customers, Orders, Products) to understand:
- Data Quality & Cleaning Steps
- Customer Behavior Toward Discounts
- Best-Performing Discounted Products
- Actionable Recommendations to Boost Sales

The study combines SQL queries, data cleaning, and profitability analysis to provide data-driven insights into the effectiveness of discounts across markets and products.

## Part A: Data Examination & Cleaning
### Steps Taken & Rationale
#### 1.	Check for NULLs in Key Fields
- Critical IDs (CustomerID, OrderNumber, ProductCode) must not be missing.
- Purpose: Prevents data loss in joins and tracking.
#### 2.	Handling NULL / Missing Values
- Fix NetSales = UnitSales × DiscountedPrice
- Fix UnitSales (back-calculated from NetSales ÷ DiscountedPrice)
- Fix OriginalPrice using consistent ProductCode reference
- Fix GrossProfit using per-unit calculations
- Purpose: Restores missing financial values using business logic.
#### 3.	Detect and Handle Invalid Values
- Flagged negative/zero values in sales, prices, and profit.
- Deleted rows with all-zero financials.
- Purpose: Removes corrupted or meaningless records.
#### 4.	Validate Price Logic
- Ensured DiscountedPrice ≤ OriginalPrice.
- Purpose: Correct mis-recorded discounts.
#### 5.	Check for Duplicates
- Identified and removed duplicate orders.
- Purpose: Prevents inflated sales totals.
#### Outcome: Dataset cleaned, consistent, and ready for analysis.

## Part B: Analysis of Sales from Products on Discount
### Key Insights
#### Market Responsiveness
-	EU: most discount-sensitive (51.8%).
-	UK: nearly identical responsiveness (51.7%) but with the largest absolute discount sales (£155,859).
-	US: least responsive (34.5%), despite a large customer base.
#### Customer Behavior
-	Over 50% of customers in EU, UK, and Asia buy only discounted products.
-	ROW & US: more price-insensitive shoppers (36–40% only-discount buyers).
#### Sales Impact
-	Discounts account for ~45–52% of sales in most regions.
-	US lags, with just 29% of sales discount-driven.
-	UK’s discount sales (£155.86K) are ~269x larger than ROW (£580).
#### Finding: EU and UK markets are highly responsive to discount promotions.

## Part C: Best-Performing Discounted Products
### Methodology
#### Metrics Chosen:
- Gross Profit Margin (GPM): GrossProfit / NetSales → shows post-discount profitability.
- Discount Impact Ratio (DIR): GrossProfit / DiscountAmount → profit generated per unit of discount given.
#### Steps:
-	Calculated discount amounts and profitability metrics.
-	Filtered to actual discounted products.
-	Aggregated performance by product.
-	Ranked products by:
1.	Gross Profit Margin
2.	Discount Impact Ratio
3.	Total Gross Profit
#### Findings
##### Dalmore 12yo → Top performer
-	GPM: 26.06%
-	DIR: 3.42
-	Insight: Premium positioning, discounts effectively boost sales.
##### Caol Ila 12yo → Strong performance
-	GPM: 25.5%
-	Balanced discounts (9.27%) keep profitability high.
#### Lagavulin 16yo → Weak performer
-	GPM: 3.86% despite 10.12% discount.
-	Insight: Discounts not translating to profit → poor ROI.

## Part D: Recommendations
#### 1. Market-Specific Discount Strategies
##### 	EU & UK (High Sensitivity):
- Loyalty tiers with extra discounts.
-	Flash sales + bundles (UK’s £155K discount sales support bundling).
##### Asia & ROW (Moderate Sensitivity):
-	Test deeper short-term discounts.
-	Try non-discount incentives (e.g., free shipping).
##### US (Low Sensitivity):
-	Reduce discount reliance.
-	Focus on experiential promotions (e.g., tastings, bundles without discount messaging).
#### 2. Leverage Top-Performing Discounts
-	Feature Dalmore 12yo in campaigns.
-	Test deeper discounts for Caol Ila 12yo.
-	Bundle Loch Lomond 18yo + Dalmore 12yo as a premium set.
#### 3. Revise Underperforming Discounts
-	Reduce Lagavulin 16yo discount depth (from 10.1% → 5–7%).
-	Adjust Glenfiddich 18yo discounts (19.6% → 12–15%).
-	Reposition Don Julio 1942 with premium branding and smaller discounts.
#### 4. Cross-Market Opportunities
-	Pilot launches in UK (high discount-driven sales).
-	Extend EU strategies to ROW.
-	Create US-specific bundles without heavy discounting.

## Limitations of the Dataset
-	Covers only 6 months → misses seasonal effects (e.g., holidays, Black Friday).
-	Limited visibility on customer lifecycle (long-term loyalty unknown).
-	No external context (competitor pricing, macro trends).
### Future Data Needs:
-	12+ months of sales (to capture seasonality).
-	Customer tenure & lifetime value.
-	Competitor discounting patterns.
## Tools & Technologies
-	SQL → Data cleaning, Querying & segmentation
-	Excel → Initial exploration
-	Power BI → Dashboards
## Key Takeaways
-	Discounts strongly influence EU & UK markets, less so in the US.
-	Dalmore 12yo and Caol Ila 12yo demonstrate discount-driven profitability.
-	Poor ROI on heavily discounted products (Lagavulin, Glenfiddich) → need pricing revision.
-	Balanced, market-specific discounting outperforms blanket strategies.



