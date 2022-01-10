import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// https://github.com/itamir/f_contact_ex
void main() => runApp( const MaterialApp(
  home: Home(),
  debugShowCheckedModeBanner: false,
));

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPosition;
  List _toDoList = [];

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
        _refresh();
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = {};
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["status"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do List"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Flexible(
                  child: 
                  TextField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.blueGrey)
                    ),
                  ),
                ),
                ButtonTheme(
                  child: ElevatedButton(
                    child: const Text("+"),
                    onPressed: _addToDo,
                  )
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _toDoList.length,
              itemBuilder: buildItem
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem (BuildContext context, int i) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[i]);
          _lastRemovedPosition = i;
          _toDoList.removeAt(i);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved['title']} removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: const Alignment(-0.9, 0.0),
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white,),
              Container(
                padding: const EdgeInsets.only(left: 10),
                child: const Text("Deletar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  ),
                ),
              )
            ],
          ),
        )
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[i]['title']),
        value: _toDoList[i]['status'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[i]['status'] ?
          Icons.check : Icons.error),
        ),
        onChanged: (status) {
          setState(() {
            _toDoList[i]['status'] = status;
            _refresh();
            _saveData();
          });
        }
      )
    );
  }

  Future _refresh() async {
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _toDoList.sort((a,b) {
        if(a['status'] && !b['status']) {
          return 1;
        } else if(!a['status'] && b['status']) {
          return -1;
        } else {
          return 0;
        }
      });
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return "";
    }
  }
}
