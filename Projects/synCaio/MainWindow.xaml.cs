
using MySql.Data.MySqlClient;
using System.Data;
using System.Data.OleDb;
using System.Windows;
using System.Configuration;
using System.Windows.Media;
using System;
using System.Globalization;

namespace synCaio
{
    /// <summary>
    /// Logica di interazione per MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            MySqlConnection connectionMysql = null;
            OleDbConnection connectionCaio = null;
            try
            {
                textBox1.Text = "sincronizzazione in corso";
                
                var myDataTable = new DataTable();
                string connectionStringCaio = ConfigurationSettings.AppSettings["ConnectionStringCaio"];
                string connectionStringMysql = ConfigurationSettings.AppSettings["ConnectionStringMysql"];
                
                connectionCaio = new OleDbConnection(connectionStringCaio);
                connectionCaio.Open();

                connectionMysql = new MySqlConnection(connectionStringMysql);
                connectionMysql.Open();

                //SINCRO ARTICOLI
                var queryRead = "SELECT IDArticolo, CodArt, DescrArt, Prz1 * 100.0 AS Prz1x100 FROM T_CaioArbase ORDER BY IDArticolo";
                var command = new OleDbCommand(queryRead, connectionCaio);
                var reader = command.ExecuteReader();
                decimal decimalPrice;

                MySqlCommand commandMysql = connectionMysql.CreateCommand();
                commandMysql.CommandText = "TRUNCATE TABLE anagrafica_articolo";

                commandMysql.ExecuteNonQuery();

                while (reader.Read())
                {
                    commandMysql.CommandText = "INSERT INTO anagrafica_articolo (articolo_id, articolo_codice, articolo_descrizione, articolo_prezzo, is_attivo) VALUES (?IDArticolo, ?CodArt, ?DescrArt, ?Prz1x100 / 100.0, 0)";
                    //textBox1.Text = reader[0].ToString();
                    commandMysql.Parameters.Clear();
                    commandMysql.Parameters.AddWithValue("?IDArticolo", MySqlDbType.VarChar).Value = reader[0].ToString();
                    commandMysql.Parameters.AddWithValue("?CodArt", reader[1].ToString());
                    commandMysql.Parameters.AddWithValue("?DescrArt", reader[2].ToString());
                    //commandMysql.Parameters.AddWithValue("?Prz1", reader[3].ToString());
                    if (Decimal.TryParse(reader[3].ToString(), out decimalPrice))
                    {
                        commandMysql.Parameters.AddWithValue("?Prz1x100", MySqlDbType.Decimal).Value = decimalPrice;
                    }
                    else
                    {
                        commandMysql.Parameters.AddWithValue("?Prz1x100", MySqlDbType.Decimal).Value = DBNull.Value;
                    }

                    commandMysql.ExecuteNonQuery();
                }

                //SINCRO FORNITORI
                var queryRead1 = "SELECT IdClifor, Rag1 FROM T_CaioClifor WHERE TipoCodice = 6 ORDER BY IdClifor";
                var command1 = new OleDbCommand(queryRead1, connectionCaio);
                reader = command1.ExecuteReader();

                MySqlCommand commandMysql1 = connectionMysql.CreateCommand();
                commandMysql1.CommandText = "TRUNCATE TABLE anagrafica_cliente";

                commandMysql1.ExecuteNonQuery();

                while (reader.Read())
                {
                    commandMysql1.CommandText = "INSERT INTO anagrafica_cliente (cliente_id, cliente_ragione_sociale, is_attivo) VALUES (?IdClifor, ?Rag1, 0)";
                    //textBox1.Text = reader[0].ToString();
                    commandMysql1.Parameters.Clear();
                    commandMysql1.Parameters.AddWithValue("?IdClifor", MySqlDbType.VarChar).Value = reader[0].ToString();
                    commandMysql1.Parameters.AddWithValue("?Rag1", reader[1].ToString());
                    commandMysql1.ExecuteNonQuery();
                }

                textBox1.Text = "sincronizzazione terminata!";
                textBox1.Background = Brushes.Green;
                connectionMysql.Close();
                connectionCaio.Close();
            }
            catch (Exception ex)
            {
                textBox1.Text = ex.ToString();
                textBox1.Background = Brushes.Red;
            }
        }
    }
}
