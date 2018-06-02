pragma solidity ^0.4.19;

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

    /* NAme of table. */
		bytes32 name;

    /* Number of rows in table. */
    uint size;

    /* Number of columns in table. */
    uint width;

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

  }

  /* 
   * Adds a row to a table.
   * 
   * @param _tableName Name of table
   */
  function createRow(DB storage self, bytes32 _tableName) public {
    // Increment table size.
  }

  /* 
   * Delete a row from the table.
   * 
   * @param _row Index of row to delete
   */
  function deleteRow(DB storage self, uint _row) public {
    
  }

  /* 
   * Create a column within a table.
   * 
   * @param _tableName Name of table
   * @param _default Default value, in bytes
   */
  function createColumn(DB storage self, 
    bytes32 _tableName, bytes _default) public {

  }

  /* 
   * Delete a column within a table.
   * 
   * @param _tableName Name of table
   * @param _columnName Name of column to delete
   */
  function deleteColumn(DB storage self, bytes32 _columnName) public {

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

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    require(table.size > _row);

    // Calculate data hash that will be used as cache when fetching.
    bytes32 hash = keccak256(_columnName, _data);

    // Fetch column index.
    uint column = table.columnIndices[_columnName];
 
    // Fetch cell in coordinate.
    Cell storage cell = table.cells[_row][column];

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
    cell.column = column;
    cell.data = _data;
    cell.dataHash = keccak256(_data);
    cell.columnHash = keccak256(_columnName, _data);
    cell.deleted = false;

    // Insert cell to table.
    table.cells[_row][column] = cell;
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

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    require(table.size > _row);

    // Fetch index of column corresponding to the given name.
    uint column = table.columnIndices[_columnName];

    // Fetch cell in coordinate.
    Cell storage cell = table.cells[_row][column];

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
   * @returns Extracted data
   */
  function read(DB storage self, bytes32 _tableName, uint _row, bytes32 _columnName) 
    public view returns (bytes) {

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Fetch index of column corresponding to the given name.
    uint column = table.columnIndices[_columnName];

    // Load data in (row, column).
    return table.cells[_row][column].data;
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

    // Load corresponding table.
    Table storage table = self.tables[_tableName];

    // Fetch column index corresponding to given column name.
    uint column = table.columnIndices[_columnName];

    // Calculate data hash that serves as the key to data cache.
    bytes32 hash = keccak256(_columnName, _data);

    // Fetch rows with same hash.
    uint[] storage rows = table.cache[hash];

    // Generate a new list and collect rows of non-deleted cells.
    uint[] storage filteredRows;

    for (uint i = 0; i < rows.length; i++) {
      Cell storage cell = table.cells[rows[i]][column];
      if (!cell.deleted) {
        filteredRows.push(rows[i]);
      }
    }

    return filteredRows;
  }

}