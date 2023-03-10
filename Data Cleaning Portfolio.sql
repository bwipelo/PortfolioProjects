--Standardise Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing;

/*You could also say 

UPDATE NashvilleHousing
SET SaleDate - CONVERT(Date, SaleDate);
OR
ALTER TABLE NashvilleHousing
ALTER SaleDate Date;*/

--Populate Property Address Data
--Where there's a duplicate parcelid & one of them has no property address, tell sql to take populate the property address
--Do a self join make sure that u are not pulling data from the same row

SELECT * --PropertyAddress
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

--Use ISNULL to check where property address is null/empty in either of the two addresses
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ] --The uniqueid field is unique so use it to distinguish
WHERE a.PropertyAddress IS NULL;

--Now to update...When doing an update in a join u can't refer to the table as its name, u have to use the alias u created

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ] --The uniqueid field is unique so use it to distinguish
WHERE a.PropertyAddress IS NULL;

--Breaking out address into individual columns(address, city, state)

SELECT PropertyAddress
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID;

--1 is the character index/position. Use the minus 1 to tell sql to remove the comma at the end of the address as well

SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM NashvilleHousing;

--To separate or delimit two values from a column u have to create a new column for that value to go into
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);


UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));


--Let's try something other than Substring to split the address.
--The parsename function requires 2 argument(s). 1 for what the delimitor currently is & what u are changing it to.


SELECT OwnerAddress
FROM NashvilleHousing;

SELECT PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1);

--Chnage Y & N to Yes & No in "Sod as Vacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END;

--Remove Duplicates
--Do a CTE to find where there are duplicates
--You need to be able to identify those duplicates. You can use row numbers or rank
--Partition it by things that should be unique. Pretend UniqueID is not there
--Remove duplicates using row number as a unique identifier. 

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS Row_Num
FROM NashvilleHousing
)
--SELECT *
--DELETE 
FROM RowNumCTE
WHERE Row_Num > 1
ORDER BY PropertyAddress;

--Delete Unused Columns

--Good practice to always check what you are able to remove is what you intent
SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;