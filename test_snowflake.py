import snowflake.connector

try:
    conn = snowflake.connector.connect(
        account="LOGWHRN-DS16138",
        user="zakariadev",
        password="MagnusCarlsen0109817er@r",
        warehouse="REAL_ESTATE_WH",
        database="REAL_ESTATE_DB",
        schema="PUBLIC",
        role="ACCOUNTADMIN",
    )

    print("Connected successfully!")
    conn.close()

except Exception as e:
    print("ERROR:")
    print(e)
