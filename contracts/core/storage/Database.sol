pragma solidity ^0.4.24;

import "../../libs/SafeMath.sol";

library Database {

  using SafeMath for uint;

  /* Database. */
  struct DB {

    /* Holds table instances. */
    mapping(bytes32 => Table) tables;
  }

  /* Represents a table. */
	struct Table {

    /* Name of table. */
		bytes32 name;

    /* Number of rows in table. */
    uint size;

    /* Number of columns in table. */
    uint width;

    /* Index of next added row. */
    uint nextRow;

    /* Index of next added column. */
    uint nextColumn;

    /* Stores row descriptord. */
    mapping(uint => Row) rows;

    /* Stores matrix of cells. */
    mapping(uint => Column) columns;

    /* Stores matrix of cells. */
    mapping(uint => mapping(uint => Cell)) cells;

    /* Maps column names to column indices. */
    mapping(bytes32 => uint) columnIndices;

    /* Maps column indices to column names. */
    mapping(uint => bytes32) columnNames;

    /* Hash of column name and bytes, for faster access. 
       Used when querying rows with specific column values. 
       Keys are created with keccak256(column name, bytes). */
    mapping(bytes32 => uint[]) cache;
	}

  /* Represents a database row. */
  struct Row {
    uint index;
    bool deleted;
  }

  /* Represents a database column. */
  struct Column {
    uint index;
    bytes32 name;
    bool deleted;
  }

  /* Represents a database cell. */
  struct Cell {

    /* Coordinates. */
    uint row;
    uint column;

    /* Actual stored data. */
    bytes data;

    /* Metadata. */
    bytes32 dataHash; // Hash of data.
    bytes32 columnHash; // Hash of columnName and data.
    uint cacheIndex; // Index of row within table.cache.
    bool deleted;
  }

  /* 
   * Create a table within a database.
   * 
   * @param _name Name of table
   */
  function createTable(DB storage self, bytes32 _name) public {

    /* Create table. */
    Table memory table;
    table.name = _name;
    table.size = 0;
    table.width = 0;
    table.nextRow = 0;
    table.nextColumn = 0;

    /* Store table. */
    self.tables[_name] = table;
  }

  /* 
   * Adds a row to a table.
   * 
   * @param _tableName Name of table
   */
  function createRow(DB storage self, bytes32 _tableName) public {
    // Increment table size.
    Table storage table = self.tables[_tableName];

    // Create Row instance.
    Row memory row;
    row.index = table.nextRow;
    row.deleted = false;

    // Store newly created Row instance to storage.
    table.rows[table.nextRow] = row;

    // Set table metadata.
    table.size = table.size.add(1);
    table.nextRow = table.nextRow.add(1);
  }

  /* 
   * Delete a row from the table.
   * 
   * @param _tableName Name of table
   * @param _row Index of row to delete
   */
  function deleteRow(DB storage self, bytes32 _tableName, uint _row) public {

    require(hasRow(self, _tableName, _row));

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Load corresponding row.
    Row storage row = table.rows[_row];

    row.deleted = true;

    // Decrement table size.
    table.size = table.size.sub(1);
  }

  /* 
   * Create a column within a table.
   * 
   * @param _tableName Name of table
   * @param _columnName Name of column to delete
   * @param _default Default value, in bytes
   */
  function createColumn(DB storage self, 
    bytes32 _tableName, bytes32 _columnName, bytes _default) public {

    // Increment table width.
    Table storage table = self.tables[_tableName];

    // Create Column instance.
    Column memory column;
    column.index = table.nextColumn;
    column.name = _columnName;
    column.deleted = false;

    // Store newly created Row instance to storage.
    table.columns[table.nextColumn] = column;

    // Set table metadata.
    table.width = table.width.add(1);
    table.nextColumn = table.nextColumn.add(1);
  }

  /* 
   * Delete a column within a table.
   * 
   * @param _tableName Name of table
   * @param _columnName Name of column to delete
   */
  function deleteColumn(DB storage self, 
    bytes32 _tableName, bytes32 _columnName) public {

    bool hasCol;
    uint columnIndex;
    (hasCol, columnIndex) = hasColumn(self, _tableName, _columnName);
    require(hasCol);

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Load corresponding column.
    Column storage column = table.columns[columnIndex];

    column.deleted = true;

    // Decrement table width.
    table.width = table.width.sub(1);
  }

  /* 
   * Write data to a cell within a table.
   * 
   * @param _tableName Name of table
   * @param _row Row index to write to
   * @param _columnName Column name to write to
   * @param _bytes Data to put in
   */
  function write(DB storage self, bytes32 _tableName, 
    uint _row, bytes32 _columnName, bytes _data) public {

    require(hasRow(self, _tableName, _row));

    bool hasCol;
    uint columnIndex;
    (hasCol, columnIndex) = hasColumn(self, _tableName, _columnName);
    require(hasCol);

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Load corresponding row.
    Row storage row = table.rows[_row];

    // Load corresponding column.
    Column storage column = table.columns[columnIndex];

    // Calculate data hash that will be used as cache when fetching.
    bytes32 hash = keccak256(_columnName, _data);

    // Fetch cell in coordinate.
    Cell storage cell = table.cells[_row][columnIndex];

    // Fetch array of rows that contan same data in same column.
    uint[] storage rows = table.cache[cell.columnHash];

    // If existing data is not empty, remove its hash from cache(table.cache).
    if (cell.dataHash != 0x0) {
      rows[cell.cacheIndex] = _row;
      cell.cacheIndex = cell.cacheIndex;
    } else {
      // If data did not exist, append current row to existing rows.
      cell.cacheIndex = rows.length;
      rows.push(_row);
    }

    // Write to cell.
    cell.row = _row;
    cell.column = columnIndex;
    cell.data = _data;
    cell.dataHash = keccak256(_data);
    cell.columnHash = keccak256(_columnName, _data);
    cell.deleted = false;

    // Insert cell to table.
    table.cells[_row][columnIndex] = cell;
  }

  /* 
   * Delete cell from table.
   * 
   * @param _tableName Name of table
   * @param _row Row index to read from
   * @param _columnName Column name to read from
   * @param _bytes Extracted data
   */
  function deleteCell(DB storage self, bytes32 _tableName, 
    uint _row, bytes32 _columnName) public {

    require(hasRow(self, _tableName, _row));

    bool hasCol;
    uint columnIndex;
    (hasCol, columnIndex) = hasColumn(self, _tableName, _columnName);
    require(hasCol);

    // Load corresponding table.
    Table storage table = self.tables[_tableName];
    
    // Load corresponding row.
    Row storage row = table.rows[_row];

    // Fetch cell in coordinate.
    Cell storage cell = table.cells[_row][columnIndex];

    // Remove cell contents.
    // cell.row = 0;
    // cell.column = 0;
    // cell.data = "";
    // cell.dataHash = 0x0;
    // cell.columnHash = 0x0;
    // cell.cacheIndex = 0;
    cell.deleted = true;
  }

  /* 
   * Read data in a cell within a table.
   * 
   * @param _tableName Name of table
   * @param _row Row index to read from
   * @param _columnName Column name to read from
   * @returns Whether data is not deleted
   * @returns Extracted data
   */
  function read(DB storage self, bytes32 _tableName, uint _row, bytes32 _columnName) 
    public view returns (bool, bytes) {

    require(hasRow(self, _tableName, _row));

    bool hasCol;
    uint columnIndex;
    (hasCol, columnIndex) = hasColumn(self, _tableName, _columnName);
    require(hasCol);

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Load corresponding cell.
    Cell storage cell = table.cells[_row][columnIndex];

    // Find out if cell is deleted. Row deletion was checked in hasRow. 
    bool intact = !cell.deleted;

    // Return availability and data in (row, column).
    return (intact, cell.data);
  }

  /* 
   * Query row ids that has a given byte as entry for a specific column.
   * 
   * @param _tableName Name of table
   * @param _columnName Column name to read from
   * @param _data Data to match for
   * @return _row Array containing row indices that match the query
   */
  function query(DB storage self, bytes32 _tableName, bytes32 _columnName, bytes _data) 
    public view returns (uint[]) {

    bool hasCol;
    uint columnIndex;
    (hasCol, columnIndex) = hasColumn(self, _tableName, _columnName);
    require(hasCol);

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Calculate data hash that serves as the key to data cache.
    bytes32 hash = keccak256(_columnName, _data);

    // Fetch rows with same hash.
    uint[] storage rows = table.cache[hash];

    // Generate a new list and collect rows of non-deleted cells.
    uint[] storage filteredRows;

    for (uint i = 0; i < rows.length; i++) {
      Row storage row = table.rows[rows[i]];
      if (!row.deleted) {
        filteredRows.push(rows[i]);
      }
    }

    return filteredRows;
  }

/* 
   * Query db size.
   * 
   * @param _tableName Name of table
   * @returns Whether the row exists
   */
  function tableSize(DB storage self, 
    bytes32 _tableName) public view returns (uint) {

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    return table.size;
  }

  /* 
   * Query db width.
   * 
   * @param _tableName Name of table
   * @returns Whether the row exists
   */
  function tableWidth(DB storage self, 
    bytes32 _tableName) public view returns (uint) {

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    return table.width;
  }

  /* 
   * Query if a row of index exists.
   * 
   * @param _tableName Name of table
   * @param _row Row index to query
   * @returns Whether the row exists
   */
  function hasRow(DB storage self, 
    bytes32 _tableName, uint _row) public view returns (bool) {

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Load corresponding row.
    Row storage row = table.rows[_row];

    bool withinRange = table.nextRow > _row;
    bool notDeleted = !row.deleted;

    return withinRange && notDeleted;
  }

  /* 
   * Query if a column with name exists.
   * 
   * @param _tableName Name of table
   * @param _columnName Column name to query
   * @returns Whether the column name exists
   * @returns Column index, if found
   */
  function hasColumn(DB storage self, 
    bytes32 _tableName, bytes32 _columnName) public view returns (bool, uint) {

    // Load corresponding table.
    Table storage table = self.tables[_tableName];
    
    // Load column index.
    uint columnIndex = table.columnIndices[_columnName];

    // Load corresponding row.
    Column storage column = table.columns[columnIndex];

    bool withinRange = table.nextColumn > columnIndex;

    bool notDeleted = !column.deleted;

    /* Weed out false positives when checking if provided column name exists.
       If the column name did not exist, columnIndex would be 0.
       String comparison is better when done after hashing with keccak256. */
    bool indexMatches = keccak256(table.columnNames[columnIndex]) 
                        == keccak256(_columnName); 

    bool hasCol = withinRange && notDeleted && indexMatches;

    return (hasCol, columnIndex);
  }

}