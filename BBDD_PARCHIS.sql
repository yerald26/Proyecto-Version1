#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <mysql/mysql.h>

// Funciones de base de datos
MYSQL* conectar_bd();
void consultar_nombre(char* id_usuario, char* respuesta);
void consultar_mail(char* id_usuario, char* respuesta);
void consultar_password(char* id_usuario, char* respuesta);

int main(int argc, char *argv[]) {
	
	int sock_conn, sock_listen, ret;
	struct sockaddr_in serv_adr;
	char peticion[512];
	char respuesta[512];
	// 	INICIALIZACIONES
	//	abrimos el socket "de esucha"
	if((sock_listen = socket(AF_INET, SOCK_STREAM, 0)) < 0)
		printf("Error creando socker");
	
	//INICILAIZA la estructura de datos
	
	memset(&serv_adr, 0, sizeof(serv_adr));
	serv_adr.sin_family = AF_INET;
	
	serv_adr.sin_addr.s_addr = htonl(INADDR_ANY);
	
	
	// Puerto de escuha (HAY QUE CAMBIARLO)!!!!!
	serv_adr.sin_port = htonl(9050);
	if(bind(sock_listen, (struct sockaddr *) &serv_adr, sizeof(serv_adr)) <0)
		printf ("Error en el bind");
	
	//M￡ximo de 3 peticiones encoladas atendidas por el servidor
	if (listen(sock_listen, 3) < 0)
		printf("Error en el Listen");
	
	int i;
	//Atenderemos solo 5 peticiones
	for (i=0; i<5; i++){
		printf("Escuchando\n");
		
		//Acepta la conexion para el socket de esucha "sock_listen" distinto al sock_conn.
		//"sock_conn" es el socket de escucha por el cual el cliente se ha conectado 
		//y el servidor usar￡ para devolver la informacion pedida.
		sock_conn = accept(sock_listen, NULL, NULL);
		printf ("He recibido conexi￳n\n");
		//Sock_conn es el socket que usaremos para el cliente
		
		//Ahora recibimos su nombre, que dejamos en el buss, guarda la pericion en el vector peticion
		//ret te dice la cantidad de bytes del mensaje, el tama￱o.
		ret = read(sock_conn, peticion, sizeof(peticion));
		printf("Recibido\n");
		
		//Tenemos que a￱adirle la marca de fin de string
		//para que no escriba lo que hay despu￩s en el buffer
		peticion[ret]='\0';
		
		//Escribimos nombre en la consola
		printf ("peticion; %s\n", peticion);
		
		//vamos a ver que quieren
		//strtok trocea el mensaje recibido, separa nombres numeros codigos...
		//en este caso corta donde hay una barra
		char *p = strtok( peticion, "/");
		//Coge el trozo desde el inicio hasta la barra y lo pone en el codugo
		int codigo = atoi (p);
		//coge el codigo de la barra hasta el final
		p = strtok( NULL, "/");
		char id_usuario[50];
		strcpy (id_usuario, p);
		//Limipiar respuesta
		memset(respuesta, 0, sizeof(respuesta));
		
		// Dependiendo del cￃﾳdigo, realizamos diferentes consultas
		if (codigo == 1) {
			// Consultar nombre
			consultar_nombre(id_usuario, respuesta);
		}
		else if (codigo == 2) {
			// Consultar correo
			consultar_mail(id_usuario, respuesta);
		}
		else if (codigo == 3) {
			// Consultar contraseￃﾱa
			consultar_password(id_usuario, respuesta);
		}
		
			printf ("Respuesta: %s\n", respuesta);
			//lo enviamos
			write(sock_conn, respuesta, strlen(respuesta));
			
			//se acabo el servicio para este clienre
			close(sock_conn);
	}
}

// Conexion a la base de datos
MYSQL* conectar_bd() {
	MYSQL *conn;
	conn = mysql_init(NULL);
	if (conn == NULL) {
		printf("Error al crear el objeto MySQL: %s\n", mysql_error(conn));
		exit(1);
	}
	
	// Conectar a la base de datos
	if (mysql_real_connect(conn, "localhost", "usuario", "password", "BBDD_PARCHIS", 0, NULL, 0) == NULL) {
		printf("Error al conectar a la base de datos: %s\n", mysql_error(conn));
		mysql_close(conn);
		exit(1);
	}
	
	return conn;
}

// Consultar nombre del usuario
void consultar_nombre(char* id_usuario, char* respuesta) {
	MYSQL *conn = conectar_bd();
	MYSQL_RES *res;
	MYSQL_ROW row;
	
	char consulta[256];
	sprintf(consulta, "SELECT Nombre_Usuario FROM usuario WHERE ID_Usuario = '%s'", id_usuario);
	
	if (mysql_query(conn, consulta)) {
		printf("Error en la consulta: %s\n", mysql_error(conn));
		strcpy(respuesta, "Error en la consulta");
		mysql_close(conn);
		return;
	}
	res = mysql_store_result(conn);
	if (res == NULL) {
		printf("Error al obtener resultados: %s\n", mysql_error(conn));
		strcpy(respuesta, "Error en la consulta");
		mysql_close(conn);
		return;
	}
	
	if ((row = mysql_fetch_row(res))) {
		sprintf(respuesta, "Nombre: %s", row[0]);
	} else {
		strcpy(respuesta, "Usuario no encontrado");
	}
	
	mysql_free_result(res);
	mysql_close(conn);
}

// Consultar correo del usuario
void consultar_mail(char* id_usuario, char* respuesta) {
	MYSQL *conn = conectar_bd();
	MYSQL_RES *res;
	MYSQL_ROW row;
	
	char consulta[256];
	sprintf(consulta, "SELECT mail FROM usuario WHERE ID_Usuario = '%s'", id_usuario);
	
	if (mysql_query(conn, consulta)) {
		printf("Error en la consulta: %s\n", mysql_error(conn));
		strcpy(respuesta, "Error en la consulta");
		mysql_close(conn);
		return;
	}
	
	res = mysql_store_result(conn);
	if (res == NULL) {
		printf("Error al obtener resultados: %s\n", mysql_error(conn));
		strcpy(respuesta, "Error en la consulta");
		mysql_close(conn);
		return;
	}
	
	if ((row = mysql_fetch_row(res))) {
		sprintf(respuesta, "Correo: %s", row[0]);
	} else {
		strcpy(respuesta, "Usuario no encontrado");
	}
	
	mysql_free_result(res);
	mysql_close(conn);
}

// Consultar contraseￃﾱa del usuario
void consultar_password(char* id_usuario, char* respuesta) {
	MYSQL *conn = conectar_bd();
	MYSQL_RES *res;
	MYSQL_ROW row;
	
	char consulta[256];
	sprintf(consulta, "SELECT Password FROM usuario WHERE ID_Usuario = '%s'", id_usuario);
	
	if (mysql_query(conn, consulta)) {
		printf("Error en la consulta: %s\n", mysql_error(conn));
		strcpy(respuesta, "Error en la consulta");
		mysql_close(conn);
		return;
	}
	
	res = mysql_store_result(conn);
	if (res == NULL) {
		printf("Error al obtener resultados: %s\n", mysql_error(conn));
		strcpy(respuesta, "Error en la consulta");
		mysql_close(conn);
		return;
	}
	
	if ((row = mysql_fetch_row(res))) {
		sprintf(respuesta, "Contraseￃﾱa: %s", row[0]);
	} else {
		strcpy(respuesta, "Usuario no encontrado");
	}
	
	mysql_free_result(res);
	mysql_close(conn);
}