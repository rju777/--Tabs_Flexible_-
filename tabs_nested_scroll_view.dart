import 'package:flutter/material.dart';

//刷新状态
enum RefreshStatus{
  idle,
  pulling,
  ready,
  refreshing
}
//加载状态
enum LoadStatus{
  idle,
  loading,
  noMore
}

class TabsScrollViewPro extends StatefulWidget{
  const TabsScrollViewPro({super.key});

  @override
  State<StatefulWidget> createState()=>TabsScrollViewProState();
}

class TabsScrollViewProState extends State<TabsScrollViewPro>
    with SingleTickerProviderStateMixin{
  late List<String> _list1Items;
  late List<String> _list2Items;

  late TabController  _tabController;

  RefreshStatus _refreshStatus = RefreshStatus.idle;
  LoadStatus _loadStatus = LoadStatus.idle;

  double _overscrollOffset = 0.0; // 过度滚动偏移量（弹性拉伸距离）
  final double _refreshThreshold = 85.0; // 触发刷新的最小拉伸距离

  bool _needRefresh = false;

  @override
  void initState() {
    _list1Items=List.generate(20, (index)=>"列表1 初始数据 ${index+1}");
    _list2Items=List.generate(20, (index)=>"列表2 初始数据 ${index+1}");

    _tabController=TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //下拉刷新数据：
  Future<void> _onRefresh() async{
    if(_refreshStatus == RefreshStatus.refreshing) return;
    setState(() => _refreshStatus = RefreshStatus.refreshing);

    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      if(_tabController.index==0){
        _list1Items.clear();
        _list1Items.addAll(List.generate(20, (index) => "列表 ${_tabController.index+1} 刷新后的数据 ${index + 1}"));
      }else{
        _list2Items.clear();
        _list2Items.addAll(List.generate(20, (index) => "列表 ${_tabController.index+1} 刷新后的数据 ${index + 1}"));
      }
      _needRefresh = false;
      _refreshStatus = RefreshStatus.idle;
      _loadStatus = LoadStatus.idle;
      _overscrollOffset= 0.0;
    });
    debugPrint("refresh");
  }

  //上拉加载数据：
  Future<void> _onLoadMore()async{
    if(_loadStatus==LoadStatus.loading || _loadStatus==LoadStatus.noMore) return;
      final listItems = _tabController.index == 0 ? _list1Items : _list2Items;
      //设置加载数量上限:50
      if(listItems.length>=50){
        setState(() => _loadStatus = LoadStatus.noMore);
        return;
      }else{
        setState(() => _loadStatus = LoadStatus.loading);
      }

    debugPrint("load more");
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      if(_tabController.index==0){
        _list1Items.addAll(List.generate(10, (index) => "列表 ${_tabController.index+1} 加载后的数据 ${_list1Items.length+index + 1}"));
      }else{
        _list2Items.addAll(List.generate(10, (index) => "列表 ${_tabController.index+1} 加载后的数据 ${_list2Items.length+index + 1}"));
      }
      _loadStatus=LoadStatus.idle;
    });
  }

// 处理滚动通知
  bool _handleScrollNotification(ScrollNotification notification) {
    // debugPrint("${notification.metrics.pixels} ? ${notification.metrics.minScrollExtent}");
    // debugPrint("${notification.metrics.pixels} ? ${notification.metrics.maxScrollExtent}");
    // debugPrint("${notification is OverscrollNotification}");

    // 1. 处理过度滚动通知（弹性拉伸/压缩时触发）
    if (notification.metrics.pixels < notification.metrics.minScrollExtent ||
    notification.metrics.pixels >notification.metrics.maxScrollExtent ) {
        // 下拉过度滚动（负值：顶部拉伸），上拉过度滚动（正值：底部拉伸）
      setState(() {
        // 累加过度滚动偏移量（下拉为负，转为正值方便计算）
        _overscrollOffset = notification.metrics.pixels < notification.metrics.minScrollExtent ?
        notification.metrics.minScrollExtent - notification.metrics.pixels : notification.metrics.pixels - notification.metrics.maxScrollExtent;
        //debugPrint("$_overscrollOffset");
        //debugPrint("$_refreshStatus");

        // 下拉刷新：根据拉伸距离更新刷新状态
        if (notification.metrics.pixels < 0 && _refreshStatus != RefreshStatus.refreshing) {
          // debugPrint("下拉...");
          //debugPrint("$_overscrollOffset");
          if (_overscrollOffset >= _refreshThreshold) {
            _refreshStatus = RefreshStatus.ready;
            _needRefresh = true; // 已达阈值，松手刷新
          } else {
            _refreshStatus = RefreshStatus.pulling; // 下拉中，未达阈值
          }
        }

        // 上拉加载：仅当滚动到底部且过度滚动时（模拟弹性拉伸触发）
        if (notification.metrics.pixels > 0 && _loadStatus == LoadStatus.idle && _refreshStatus != RefreshStatus.refreshing) {
          //debugPrint("上拉...");
          _onLoadMore();
        }
      });
    }

    // 2. 处理滚动结束通知（用户松手时触发）
    if (notification is ScrollEndNotification) {
      //debugPrint("$_refreshStatus");
      // 下拉刷新：松手时如果已达阈值，触发刷新
      //debugPrint("$_needRefresh");
      if (_needRefresh) {
        _onRefresh();
      }
      // 未达阈值，重置刷新状态
      else if (_refreshStatus == RefreshStatus.pulling) {
        setState(() => _refreshStatus = RefreshStatus.idle);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              title: const Text("Tab NestedScrollView"),
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景图
                    Image.network(
                      "https://picsum.photos/800/400",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                    ),
                    // 黑色遮罩（提升文字可读性）
                    const DecoratedBox(decoration: BoxDecoration(color: Color(0x33000000))),
                    // 拉伸提示组件（仅下拉拉伸时显示，居中）
                    if (_overscrollOffset > 0 && _refreshStatus != RefreshStatus.idle)
                      Positioned(
                        bottom: 60, // 位于 SliverAppBar 底部（TabBar 上方）
                        left: 0,
                        right: 0,
                        child: _buildRefreshHint(),
                      ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: "列表1"), Tab(text: "列表2")],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildListView(_list1Items),
            _buildListView(_list2Items),
          ],
        ),
      ),
    );
  }

// 构建下拉拉伸提示组件（箭头 + 文字）
  Widget _buildRefreshHint() {
    //debugPrint("${_refreshStatus}");
    if (_refreshStatus == RefreshStatus.refreshing) {
      // 刷新中：显示加载指示器
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: 8),
          Text("刷新中...", style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      );
    }

    // 拉伸时：显示箭头 + 文字
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 箭头：根据状态旋转（下拉时向下，达标时向上）
        AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: _refreshStatus == RefreshStatus.ready ? 0.5 : 0, // 0.5圈 = 180度
          child: const Icon(
            Icons.arrow_downward,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _refreshStatus == RefreshStatus.ready ? "松手刷新" : "下拉刷新",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRefreshHint2() {
    //debugPrint("${_refreshStatus}");
    if (_refreshStatus == RefreshStatus.refreshing) {
      // 刷新中：显示加载指示器
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: 8),
          Text("刷新中...", style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 14)),
        ],
      );
    }

    // 拉伸时：显示箭头 + 文字
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 箭头：根据状态旋转（下拉时向下，达标时向上）
        AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: _refreshStatus == RefreshStatus.ready ? 0.5 : 0, // 0.5圈 = 180度
          child: const Icon(
            Icons.arrow_downward,
            color: Colors.deepPurpleAccent,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _refreshStatus == RefreshStatus.ready ? "松手刷新" : "下拉刷新",
          style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 14),
        ),
      ],
    );
  }

  // 构建列表项（含加载更多提示）
  Widget _buildListView(List<String> items) {
    if(_refreshStatus == RefreshStatus.refreshing || _refreshStatus == RefreshStatus.pulling || _refreshStatus == RefreshStatus.ready){
      final itemCount = items.length + 1;
      bool isPrint = true;
      return NotificationListener<ScrollNotification>(
          onNotification: (notification)=>_handleScrollNotification(notification),
          child:ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if(index == 0){
                //isPrint = true;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: _buildRefreshHint2()
                  ),
                );
              }
              return ListTile(title: Text(items[index-1]));
            },
          )
      );
    }
    else{
      final itemCount = items.length + 1;
      return NotificationListener<ScrollNotification>(
          onNotification: (notification)=>_handleScrollNotification(notification),
          child:ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // 加载/无更多提示
              if (index == items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _loadStatus == LoadStatus.loading
                        ? const CircularProgressIndicator()
                        : const Text("已加载全部数据"),
                  ),
                );
              }
              return ListTile(title: Text(items[index]));
            },
          )
      );
    }
  }
}