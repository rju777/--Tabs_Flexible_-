import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CustomNSV extends StatefulWidget{
  const CustomNSV({super.key});

  @override
  State<StatefulWidget> createState() =>CustomNSVState();
}

class CustomNSVState extends State<CustomNSV>{
  final _scrollController=ScrollController();
  List<String> _listItems=List.generate(20, (index) => "初始数据 ${index + 1}");
  bool _isLoading=false;
  bool _isRefreshing=false;

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //下拉刷新数据：
  Future<void> _onRefresh() async{
    if(_isRefreshing||_isLoading) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isRefreshing = true);
      }
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _listItems.clear();
      _listItems=List.generate(20, (index) => "刷新后的数据 ${index + 1}");
      _isRefreshing=false;
    });
    debugPrint("refresh");
  }

  //上拉加载数据：
  Future<void> _loadMoreData()async{
    if(_isLoading||_isRefreshing) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
    });

    debugPrint("load more");
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _listItems.addAll(List.generate(10, (index) => "加载后的数据 ${_listItems.length+index + 1}"));
      _isLoading=false;
    });
  }

  //滚动
  void _onScroll(){
    final _position=_scrollController.position;
    //debugPrint("${_position.pixels}");
    if (_position.extentAfter==0.0&& !_isLoading) {
      _loadMoreData();
    }else if(_position.extentBefore==0.0&&_position.pixels<0&&!_isRefreshing){
      _onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        //appBar: AppBar(title: Text("appbar"),),
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              stretch: true,
              //snap: true,
              //floating: true,
              expandedHeight: 200,
              //onStretchTrigger: _onRefresh,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: _isRefreshing ? Container(
                  height: 25,
                  width: 25,
                  //padding: const EdgeInsets.all(1),
                  child:const CircularProgressIndicator(
                    strokeWidth: 2.7,
                  ),
                  // decoration: BoxDecoration(
                  //   color: Colors.white,
                  //   borderRadius: BorderRadius.circular(7),
                  //   border: Border.all(width: 1 ,color: Colors.blueAccent)
                  // ),
                ) : const Text(""),
                background: Image.network(
                  "https://picsum.photos/800/400",
                  fit: BoxFit.cover,
                ),
                stretchModes: const [
                  StretchMode.zoomBackground, // 拉伸时缩放背景
                  StretchMode.blurBackground, // 拉伸时模糊背景
                ],
              ),
            ),

            SliverFixedExtentList(
              itemExtent: 70.0,
              delegate: SliverChildBuilderDelegate((BuildContext context,int index){
                // 加载时，最后一个 item 显示进度条
                if(_isLoading){
                  if (index == _listItems.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                }
                // 刷新时，第一个 item 显示进度条
                // else if(_isRefreshing){
                //   if (index == 0) {
                //     return const Padding(
                //       padding: EdgeInsets.symmetric(vertical: 16),
                //       child: Center(child: CircularProgressIndicator()),
                //     );
                //   }
                // }

                return ListTile(
                  title: Text(_listItems[index]),
                  leading: CircleAvatar(child: Text("${index + 1}")),
                );
              },childCount: _isLoading ? _listItems.length + 1 : _listItems.length
              ),
            )
          ],
        ),
      ),
    );
  }
}