#!/usr/bin/env python3
"""
检查现有 HANA 数据库结构
用于确认 Schema、表名、字段名等信息
"""
import os
import sys

try:
    from hdbcli import dbapi
except ImportError:
    print("❌ hdbcli 未安装")
    print("请运行: pip install hdbcli")
    sys.exit(1)

# HANA 连接信息
HANA_CONFIG = {
    'host': '95fac287-84a9-45e1-89a1-c88d5fd6c10e.hana.prod-eu12.hanacloud.ondemand.com',
    'port': 443,
    'user': os.getenv('HANA_USER', ''),
    'password': os.getenv('HANA_PASSWORD', ''),
    'encrypt': True,
    'sslValidateCertificate': True
}

def check_schemas():
    """列出所有用户 Schema"""
    print("=" * 80)
    print("📊 检查现有 Schema")
    print("=" * 80)

    if not HANA_CONFIG['password']:
        print("⚠️  请先设置环境变量:")
        print("   export HANA_USER='your_user'")
        print("   export HANA_PASSWORD='your_password'")
        return

    try:
        connection = dbapi.connect(
            address=HANA_CONFIG['host'],
            port=HANA_CONFIG['port'],
            user=HANA_CONFIG['user'],
            password=HANA_CONFIG['password'],
            encrypt=HANA_CONFIG['encrypt'],
            sslValidateCertificate=HANA_CONFIG['sslValidateCertificate']
        )

        cursor = connection.cursor()

        # 查询非系统 Schema
        cursor.execute("""
            SELECT SCHEMA_NAME, OWNER_NAME, CREATE_TIME
            FROM SYS.SCHEMAS
            WHERE SCHEMA_NAME NOT IN ('SYS', 'SYSTEM', '_SYS_BIC', '_SYS_BI', '_SYS_REPO', '_SYS_RT', '_SYS_STATISTICS', '_SYS_AFL', '_SYS_XS')
            ORDER BY SCHEMA_NAME
        """)

        schemas = cursor.fetchall()

        print(f"\n找到 {len(schemas)} 个用户 Schema:\n")
        print(f"{'Schema 名称':<40} {'所有者':<20} {'创建时间'}")
        print("-" * 80)

        for schema in schemas:
            print(f"{schema[0]:<40} {schema[1]:<20} {str(schema[2])}")

        cursor.close()
        connection.close()

    except Exception as e:
        print(f"❌ 连接失败: {str(e)}")


def check_tables(schema_name):
    """检查指定 Schema 下的表"""
    print("\n" + "=" * 80)
    print(f"📋 检查 Schema: {schema_name} 的表")
    print("=" * 80)

    try:
        connection = dbapi.connect(
            address=HANA_CONFIG['host'],
            port=HANA_CONFIG['port'],
            user=HANA_CONFIG['user'],
            password=HANA_CONFIG['password'],
            encrypt=HANA_CONFIG['encrypt'],
            sslValidateCertificate=HANA_CONFIG['sslValidateCertificate']
        )

        cursor = connection.cursor()

        # 查询表
        cursor.execute("""
            SELECT TABLE_NAME, RECORD_COUNT, CREATE_TIME
            FROM SYS.TABLES
            WHERE SCHEMA_NAME = ?
            AND TABLE_TYPE = 'ROW'
            ORDER BY TABLE_NAME
        """, (schema_name,))

        tables = cursor.fetchall()

        if not tables:
            print(f"\n⚠️  Schema '{schema_name}' 中没有找到表")
            cursor.close()
            connection.close()
            return

        print(f"\n找到 {len(tables)} 个表:\n")
        print(f"{'表名':<40} {'记录数':<15} {'创建时间'}")
        print("-" * 80)

        for table in tables:
            print(f"{table[0]:<40} {table[1]:<15} {str(table[2])}")

        cursor.close()
        connection.close()

    except Exception as e:
        print(f"❌ 查询失败: {str(e)}")


def check_table_structure(schema_name, table_name):
    """检查表结构"""
    print("\n" + "=" * 80)
    print(f"🔍 检查表结构: {schema_name}.{table_name}")
    print("=" * 80)

    try:
        connection = dbapi.connect(
            address=HANA_CONFIG['host'],
            port=HANA_CONFIG['port'],
            user=HANA_CONFIG['user'],
            password=HANA_CONFIG['password'],
            encrypt=HANA_CONFIG['encrypt'],
            sslValidateCertificate=HANA_CONFIG['sslValidateCertificate']
        )

        cursor = connection.cursor()

        # 查询字段信息
        cursor.execute("""
            SELECT COLUMN_NAME, DATA_TYPE_NAME, LENGTH, IS_NULLABLE, DEFAULT_VALUE
            FROM SYS.TABLE_COLUMNS
            WHERE SCHEMA_NAME = ? AND TABLE_NAME = ?
            ORDER BY POSITION
        """, (schema_name, table_name))

        columns = cursor.fetchall()

        if not columns:
            print(f"\n⚠️  表 '{schema_name}.{table_name}' 不存在")
            cursor.close()
            connection.close()
            return

        print(f"\n表字段（共 {len(columns)} 个）:\n")
        print(f"{'字段名':<30} {'类型':<20} {'长度':<10} {'可空':<10} {'默认值'}")
        print("-" * 100)

        for col in columns:
            nullable = "是" if col[3] == 'TRUE' else "否"
            default = str(col[4]) if col[4] else "-"
            length = str(col[2]) if col[2] else "-"
            print(f"{col[0]:<30} {col[1]:<20} {length:<10} {nullable:<10} {default}")

        # 查询记录数和示例数据
        cursor.execute(f'SELECT COUNT(*) FROM "{schema_name}"."{table_name}"')
        count = cursor.fetchone()[0]

        print(f"\n记录数: {count}")

        if count > 0:
            print("\n示例数据（前 3 条）:")
            cursor.execute(f'SELECT * FROM "{schema_name}"."{table_name}" LIMIT 3')
            rows = cursor.fetchall()

            # 打印列名
            col_names = [desc[0] for desc in cursor.description]
            print("\n" + " | ".join(col_names))
            print("-" * 100)

            for row in rows:
                print(" | ".join(str(val) for val in row))

        cursor.close()
        connection.close()

    except Exception as e:
        print(f"❌ 查询失败: {str(e)}")


def main():
    """主函数"""
    print("\n" + "=" * 80)
    print("HANA 数据库结构检查工具")
    print("=" * 80)
    print()

    if not HANA_CONFIG['password']:
        print("⚠️  请先设置环境变量:")
        print("   export HANA_USER='your_user'")
        print("   export HANA_PASSWORD='your_password'")
        print()
        print("然后运行:")
        print("   python check_hana_structure.py")
        return

    # 步骤 1: 列出所有 Schema
    check_schemas()

    # 步骤 2: 让用户选择要检查的 Schema
    print("\n" + "=" * 80)
    schema_name = input("\n请输入要检查的 Schema 名称（直接回车跳过）: ").strip()

    if schema_name:
        check_tables(schema_name)

        # 步骤 3: 让用户选择要检查的表
        table_name = input("\n请输入要检查的表名称（直接回车跳过）: ").strip()

        if table_name:
            check_table_structure(schema_name, table_name)

    print("\n" + "=" * 80)
    print("检查完成！")
    print("=" * 80)


if __name__ == "__main__":
    main()
