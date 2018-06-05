pragma solidity ^0.4.24;

import "../core/storage/Database.sol";

contract DatabaseTest {

  using Database for Database.DB;

  Database.DB private db;

  /* 
   * Create a table within a database.
   * 
   * @param _name Name of table
   */
  function createTable(bytes32 _name) public {
    Database.createTable(db, _name);
  }

  /* 
   * Adds a row to a table.
   * 
   * @param _tableName Name of table
   */
  function createRow(bytes32 _tableName) public {
    Database.createRow(db, _tableName);
  }

  /* 
   * Delete a row from the table.
   * 
   * @param _tableName Name of table
   * @param _row Index of row to delete
   */
  function deleteRow(bytes32 _tableName, uint _row) public {
    Database.deleteRow(db, _tableName, _row);
  }

  /* 
   * Create a column within a table.
   * 
   * @param _tableName Name of table
   * @param _columnName Name of column to delete
   * @param _default Default value, in bytes
   */
  function createColumn(bytes32 _tableName, 
    bytes32 _columnName, bytes _default) public {

    Database.createColumn(db, _tableName, _columnName, _default);
  }

  /* 
   * Delete a column within a table.
   * 
   * @param _tableName Name of table
   * @param _columnName Name of column to delete
   */
  function deleteColumn(bytes32 _tableName, bytes32 _columnName) public {

    Database.deleteColumn(db, _tableName, _columnName);
  }

  /* 
   * Write data to a cell within a table.
   * 
   * @param _tableName Name of table
   * @param _row Row index to write to
   * @param _columnName Column name to write to
   * @param _bytes Data to put in
   */
  function write(bytes32 _tableName, 
    uint _row, bytes32 _columnName, bytes _data) public {

    Database.write(db, _tableName, _row, _columnName, _data);
  }

  /* 
   * Delete cell from table.
   * 
   * @param _tableName Name of table
   * @param _row Row index to read from
   * @param _columnName Column name to read from
   * @param _bytes Extracted data
   */
  function deleteCell(bytes32 _tableName, 
    uint _row, bytes32 _columnName) public {

    Database.deleteCell(db, _tableName, _row, _columnName);
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
  function read(bytes32 _tableName, uint _row, bytes32 _columnName) 
    public view returns (bool, bytes) {

    return Database.read(db, _tableName, _row, _columnName);
  }

  /* 
   * Query row ids that has a given byte as entry for a specific column.
   * 
   * @param _tableName Name of table
   * @param _columnName Column name to read from
   * @param _data Data to match for
   * @return _row Array containing row indices that match the query
   */
  function query(bytes32 _tableName, bytes32 _columnName, bytes _data) 
    public view returns (uint[]) {

    return Database.query(db, _tableName, _columnName, _data);
  }

  /* 
   * Query db size.
   * 
   * @param _tableName Name of table
   * @returns Whether the row exists
   */
  function tableSize(bytes32 _tableName) public view returns (uint) {

    return Database.tableSize(db, _tableName);
  }

  /* 
   * Query db width.
   * 
   * @param _tableName Name of table
   * @returns Whether the row exists
   */
  function tableWidth(bytes32 _tableName) public view returns (uint) {

    return Database.tableWidth(db, _tableName);
  }

  /* 
   * Query if a row of index exists.
   * 
   * @param _tableName Name of table
   * @param _row Row index to query
   * @returns Whether the row exists
   */
  function hasRow(bytes32 _tableName, uint _row) public view returns (bool) {

    return Database.hasRow(db, _tableName, _row);
  }

  /* 
   * Query if a column with name exists.
   * 
   * @param _tableName Name of table
   * @param _columnName Column name to query
   * @returns Whether the column name exists
   * @returns Column index, if found
   */
  function hasColumn(bytes32 _tableName, bytes32 _columnName) public view returns (bool, uint) {

    return Database.hasColumn(db, _tableName, _columnName);
  }

}