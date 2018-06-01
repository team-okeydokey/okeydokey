pragma solidity ^0.4.19;

library Database {

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
    mapping(bytes32 => uint) columnNames;
	}

  /* Represents a database cell. */
  struct Cell {

    /* Coordinates. */
    uint row;
    uint column;

    /* Actual stored data. */
    bytes data;
  }

  /* 
   * Create a table within a database.
   * 
   * @param _name Name of table.
   */
  function createTable(DB storage self, bytes32 _name) public {

  }

  /* 
   * Adds a row to a table.
   * 
   * @param _tableName Name of table.
   */
  function insert(DB storage self, bytes32 _tableName) public {

  }

  /* 
   * Create a column within a table.
   * 
   * @param _tableName Name of table.
   * @param _default Default value, in bytes.
   */
  function createColumn(DB storage self, bytes32 _tableName, bytes _default) public {

  }

  /* 
   * Create a column within a table.
   * 
   * @param _tableName Name of table.
   * @param _row Row index to write to.
   * @param _column Column name to write to.
   * @param _bytes Data to put in.
   */
  function write(DB storage self, bytes32 _tableName, uint _row, bytes32 _column, bytes _data) public {

  }

  /* 
   * Create a column within a table.
   * 
   * @param _tableName Name of table.
   * @param _row Row index to read from.
   * @param _column Column name to read from.
   * @param _bytes Extracted data.
   */
  function read(DB storage self, bytes32 _tableName, uint _row, bytes32 _column) public view returns (bytes) {

    Table storage table = self.tables[_tableName];

    uint columnIndex = table.columnNames[_column];

    return table.cells[_row][columnIndex].data;
  }

  /* 
   * Query for a specific entry.
   * 
   * @param _tableName Name of table.
   * @param _row Row index to read from.
   * @param _column Column name to read from.
   * @param _data Data to match for.
   */
  function query(DB storage self, bytes32 _tableName, uint _row, bytes _data) public view returns (bytes) {

    // Table memory table = tables[_tableName];

    // uint columnIndex = table.columnNames[_column];

    // return table.cells[_row][_column];
  }

}