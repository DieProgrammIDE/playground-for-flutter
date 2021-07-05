import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  Client client = Client();
  Account account = Account(client);
  Storage storage = Storage(client);
  Database database = Database(client);

  client
          .setEndpoint(
              'https://demo.appwrite.io/v1') // Make sure your endpoint is accessible from your emulator, use IP if needed
          .setProject('608fa1dd20ef0') // Your project ID
          // .setSelfSigned() // Do not use this in production
      ;

  runApp(MaterialApp(
    home: Playground(
      client: client,
      account: account,
      storage: storage,
      database: database,
    ),
  ));
}

class Playground extends StatefulWidget {
  Playground(
      {required this.client,
      required this.account,
      required this.storage,
      required this.database});
  final Client client;
  final Account account;
  final Storage storage;
  final Database database;

  @override
  PlaygroundState createState() => PlaygroundState();
}

class PlaygroundState extends State<Playground> {
  String username = "Loading...";
  UserModel? user;
  FileModel? uploadedFile;
  JwtModel? jwt;

  @override
  void initState() {
    _getAccount();
    super.initState();
  }

  _getAccount() async {
    try {
      final response = await widget.account.get();
      setState(() {
        username = response.name;
        user = response;
      });
    } on AppwriteException catch (error) {
      print(error.message);
      setState(() {
        username = 'No Session';
      });
    }
  }

  _uploadFile() {
    FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false)
        .then((response) {
      if (response == null) return;
      final file = response.files.single;
      if (!kIsWeb) {
        final path = file.path;
        if (path == null) return;
        FileInput.fromFile(path, filename: file.name).then((response) {
          widget.storage.createFile(
              file: response,
              read: [user != null ? "user:${user?.$id}" : '*'],
              write: ['*']).then((response) {
            print(response);
            setState(() {
              uploadedFile = response;
            });
          }).catchError((error) {
            print(error.message);
          }, test: (e) => e is AppwriteException);
        }).catchError((error) {
          print(error.message);
        }, test: (e) => e is AppwriteException);
      } else {
        if (file.bytes == null) return;
        List<int>? bytes = file.bytes?.map((i) => i).toList();
        final uploadFile = FileInput.fromBytes(bytes!, filename: file.name);
        widget.storage.createFile(
          file: uploadFile,
          read: [user != null ? "user:${user?.$id}" : '*'],
          write: ['*'],
        ).then((response) {
          print(response);
          setState(() {
            uploadedFile = response;
          });
        }).catchError((error) {
          print(error.message);
        }, test: (e) => e is AppwriteException);
      }
    }).catchError((error) {
      print(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Appwrite + Flutter = ❤️"),
          backgroundColor: Colors.pinkAccent[200]),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(20.0)),
              ElevatedButton(
                  child: Text(
                    "Anonymous Login",
                    style: TextStyle(color: Colors.black, fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey,
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () {
                    widget.account.createAnonymousSession().then((value) {
                      print(value.toMap());
                      _getAccount();
                    }).catchError((error) {
                      print(error.message);
                    }, test: (e) => e is AppwriteException);
                  }),
              const SizedBox(height: 10.0),
              ElevatedButton(
                  child: Text(
                    "Login with Email",
                    style: TextStyle(color: Colors.black, fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey,
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () {
                    widget.account
                        .createSession(
                            email: 'user@appwrite.io', password: 'password')
                        .then((value) {
                      print(value.toMap());
                      _getAccount();
                    }).catchError((error) {
                      print(error.message);
                    }, test: (e) => e is AppwriteException);
                  }),
              Padding(padding: EdgeInsets.all(20.0)),
              ElevatedButton(
                  child: Text(
                    "Create Doc",
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(280, 50),
                    primary: Colors.blue,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () {
                    widget.database
                        .createDocument(
                            collectionId:
                                '608faab562521', //change your collection id
                            data: {'username': 'hello2'},
                            read: ['*'],
                            write: ['*'])
                        .then((value) => value.convertTo<MyDocument>(
                            (map) => MyDocument.fromMap(map)))
                        .then((value) => print(value.userName))
                        .catchError((error) {
                          print(error.message);
                        }, test: (e) => e is AppwriteException);
                  }),
              const SizedBox(height: 10.0),
              ElevatedButton(
                  child: Text(
                    "Upload file",
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () {
                    _uploadFile();
                  }),
              Padding(padding: EdgeInsets.all(20.0)),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () async {
                    try {
                      jwt = await widget.account.createJWT();
                      setState(() {});
                    } on AppwriteException catch (e) {
                      print(e.message);
                    }
                  },
                  child: Text("Generate JWT",
                      style: TextStyle(color: Colors.white, fontSize: 20.0))),
              const SizedBox(height: 20.0),
              if (jwt != null) ...[
                SelectableText(
                  jwt!.jwt,
                  style: TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 20.0),
              ],
              ElevatedButton(
                  child: Text(
                    "Login with Facebook",
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () {
                    widget.account
                        .createOAuth2Session(provider: 'facebook')
                        .then((value) {
                      widget.account.get().then((user) {
                        setState(() {
                          username = user.name;
                        });
                      }).catchError((error) {
                        setState(() {
                          username = 'Anonymous User';
                        });
                      }, test: (e) => e is AppwriteException);
                    }).catchError((error) {
                      print(error.message);
                    }, test: (e) => e is AppwriteException);
                  }),
              Padding(padding: EdgeInsets.all(10.0)),
              ElevatedButton(
                  child: Text(
                    "Login with GitHub",
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black87,
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () {
                    widget.account
                        .createOAuth2Session(
                            provider: 'github', success: '', failure: '')
                        .then((value) {
                      widget.account.get().then((user) {
                        setState(() {
                          username = user.name;
                        });
                      }).catchError((error) {
                        print(error.message);
                        setState(() {
                          username = 'Anonymous User';
                        });
                      }, test: (e) => e is AppwriteException);
                    }).catchError((error) {
                      print(error.message);
                    }, test: (e) => e is AppwriteException);
                  }),
              Padding(padding: EdgeInsets.all(10.0)),
              ElevatedButton(
                  child: Text(
                    "Login with Google",
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () {
                    widget.account
                        .createOAuth2Session(provider: 'google')
                        .then((value) {
                      widget.account.get().then((response) {
                        setState(() {
                          username = response.name;
                        });
                      }).catchError((error) {
                        print(error.message);
                        setState(() {
                          username = 'Anonymous User';
                        });
                      }, test: (e) => e is AppwriteException);
                    }).catchError((error) {
                      print(error.message);
                    }, test: (e) => e is AppwriteException);
                  }),
              if (user != null && uploadedFile != null)
                FutureBuilder<Uint8List>(
                  future: widget.storage.getFileView(fileId: uploadedFile!.$id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!);
                    }
                    if (snapshot.hasError) {
                      if (snapshot.error is AppwriteException) {
                        print((snapshot.error as AppwriteException).message);
                      }
                      print(snapshot.error);
                    }
                    return CircularProgressIndicator();
                  },
                ),
              Padding(padding: EdgeInsets.all(20.0)),
              Divider(),
              Padding(padding: EdgeInsets.all(20.0)),
              Text(username,
                  style: TextStyle(color: Colors.black, fontSize: 20.0)),
              Padding(padding: EdgeInsets.all(20.0)),
              Divider(),
              Padding(padding: EdgeInsets.all(20.0)),
              ElevatedButton(
                  child: Text('Logout',
                      style: TextStyle(color: Colors.white, fontSize: 20.0)),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red[700],
                    padding: const EdgeInsets.all(16),
                    minimumSize: Size(280, 50),
                  ),
                  onPressed: () {
                    widget.account
                        .deleteSession(sessionId: 'current')
                        .then((response) {
                      setState(() {
                        username = 'No Session';
                      });
                    }).catchError((error) {
                      print(error.message);
                    }, test: (e) => e is AppwriteException);
                  }),
              Padding(padding: EdgeInsets.all(20.0)),
            ],
          ),
        ),
      ),
    );
  }
}


class MyDocument {
  final String userName;
  final String id;
  MyDocument({
    required this.userName,
    required this.id,
  });

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'id': id,
    };
  }

  factory MyDocument.fromMap(Map<String, dynamic> map) {
    return MyDocument(
      userName: map['username'],
      id: map['\$id'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MyDocument.fromJson(String source) =>
      MyDocument.fromMap(json.decode(source));

  @override
  String toString() => 'MyDocument(userName: $userName, id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MyDocument && other.userName == userName && other.id == id;
  }

  @override
  int get hashCode => userName.hashCode ^ id.hashCode;
}