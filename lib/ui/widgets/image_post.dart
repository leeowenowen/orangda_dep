import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_photo_share/common/constants/constants.dart';
import 'package:flutter_photo_share/common/utils/time_util.dart';
import 'package:flutter_photo_share/models/user.dart';
import 'package:flutter_photo_share/service/account_service.dart';
import 'package:flutter_photo_share/ui/account/profile_page.dart';
import 'package:flutter_photo_share/ui/comment/comment_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ImagePost extends StatefulWidget {
  const ImagePost(
      {this.mediaUrl,
      this.username,
      this.location,
      this.description,
      this.likes,
      this.postId,
      this.ownerId,
      this.postTime});

  factory ImagePost.fromDocument(DocumentSnapshot document) {
    Timestamp timestamp = document['timestamp'];
    int timestampmillSeconds = timestamp.millisecondsSinceEpoch;
    return ImagePost(
      username: document['username'],
      location: document['location'],
      mediaUrl: document['mediaUrl'],
      likes: document['likes'],
      description: document['description'],
      postId: document.documentID,
      ownerId: document['ownerId'],
      postTime: formatTimestamp(timestampmillSeconds)
    );
  }

  factory ImagePost.fromJSON(Map data) {
    return ImagePost(
      username: data['username'],
      location: data['location'],
      mediaUrl: data['mediaUrl'],
      likes: data['likes'],
      description: data['description'],
      ownerId: data['ownerId'],
      postId: data['postId'],
      postTime: data['timestamp'],
    );
  }

  int getLikeCount(var likes) {
    if (likes == null) {
      return 0;
    }
// issue is below
    var vals = likes.values;
    int count = 0;
    for (var val in vals) {
      if (val == true) {
        count = count + 1;
      }
    }

    return count;
  }

  final String mediaUrl;
  final String username;
  final String location;
  final String description;
  final likes;
  final String postId;
  final String ownerId;
  final String postTime;

  _ImagePost createState() => _ImagePost(
        mediaUrl: this.mediaUrl,
        username: this.username,
        location: this.location,
        description: this.description,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
        ownerId: this.ownerId,
        postId: this.postId,
    postTime: this.postTime,
      );
}

class _ImagePost extends State<ImagePost> {
  final String mediaUrl;
  final String username;
  final String location;
  final String description;
  Map likes;
  int likeCount;
  final String postId;
  bool liked;
  final String ownerId;
  final String postTime;

  bool showHeart = false;

  TextStyle boldStyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  var reference = Firestore.instance.collection(Constants.COLLECTION_POSTS);

  _ImagePost(
      {this.mediaUrl,
      this.username,
      this.location,
      this.description,
      this.likes,
      this.postId,
      this.likeCount,
      this.ownerId,
      this.postTime});

  GestureDetector buildLikeIcon() {
    Color color;
    IconData icon;

    if (liked) {
      color = Colors.pink;
      icon = FontAwesomeIcons.solidHeart;
    } else {
      icon = FontAwesomeIcons.heart;
    }

    return GestureDetector(
        child: Icon(
          icon,
          size: 25.0,
          color: color,
        ),
        onTap: () {
          _likePost(postId);
        });
  }

  GestureDetector buildLikeableImage() {
    return GestureDetector(
      onDoubleTap: () => _likePost(postId),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: mediaUrl,
            fit: BoxFit.fitWidth,
            placeholder: (context, url) => loadingPlaceHolder,
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
          showHeart
              ? Positioned(
                  child: Container(
                    width: 100,
                    height: 100,
                    child: Opacity(
                        opacity: 0.85,
                        child: FlareActor(
                          "assets/flare/Like.flr",
                          animation: "Like",
                        )),
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  buildPostHeader({String ownerId}) {
    if (ownerId == null) {
      return Text("owner error");
    }

    return FutureBuilder(
        future: Firestore.instance
            .collection(Constants.COLLECTION_USER)
            .document(ownerId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return Container(
              height: 70,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                      snapshot.data.data['photoUrl']),
                  backgroundColor: Colors.grey,
                ),
                title: GestureDetector(
                  child: Text(snapshot.data.data['username'], style: boldStyle),
                  onTap: () {
                    Navigator.of(context).pushNamed(ProfilePage.ROUTE, arguments: {
                      'userId':ownerId
                    });
                  },
                ),
                subtitle: Row(children:[IconTheme(
                  data: IconThemeData(
                      size: 15,
                      color: Colors.blue),
                  child: Icon(Icons.location_on),
                ),

                Text(this.location),]
                ),
                trailing: const Icon(Icons.more_vert),
              ),
            );
          }

          // snapshot data is null here
          return Container(
            height: 70,
          );
        });
  }

  Container loadingPlaceHolder = Container(
    height: 400.0,
    child: Center(child: CircularProgressIndicator()),
  );

  @override
  Widget build(BuildContext context) {
    liked = (likes[AccountService.googleSignIn().currentUser.id.toString()] ==
        true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(ownerId: ownerId),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
                margin: const EdgeInsets.only(left: 20.0,right: 20, bottom: 5),
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  )
                )),
          ],
        ),
        buildLikeableImage(),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: const EdgeInsets.only(left: 20.0, top: 40.0)),
            buildLikeIcon(),
            Padding(padding: const EdgeInsets.only(right: 20.0)),
            GestureDetector(
                child: const Icon(
                  FontAwesomeIcons.comment,
                  size: 25.0,
                ),
                onTap: () {
                  goToComments(
                      context: context,
                      postId: postId,
                      ownerId: ownerId,
                      mediaUrl: mediaUrl);
                }),
            Expanded(child:
            Container(
              margin:EdgeInsets.only(right: 20),
                child:Text(postTime,
                    textAlign: TextAlign.right,
                    style:TextStyle(
                  color:Colors.grey,
                  fontSize:12
                ))))
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  fontSize: 12,
                  color:Colors.grey,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  void _likePost(String postId2) {
    var userId = AccountService.googleSignIn().currentUser.id;
    bool _liked = likes[userId] == true;

    if (_liked) {
      print('removing like');
      reference.document(postId).updateData({
        'likes.$userId': false
        //firestore plugin doesnt support deleting, so it must be nulled / falsed
      });

      setState(() {
        likeCount = likeCount - 1;
        liked = false;
        likes[userId] = false;
      });

      removeActivityFeedItem();
    }

    if (!_liked) {
      print('liking');
      reference.document(postId).updateData({'likes.$userId': true});

      addActivityFeedItem();

      setState(() {
        likeCount = likeCount + 1;
        liked = true;
        likes[userId] = true;
        showHeart = true;
      });
      Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  void addActivityFeedItem() {
    User currentUserModel = AccountService.currentUser();
    Firestore.instance
        .collection(Constants.COLLECTION_FEED)
        .document(ownerId)
        .collection("items")
        .document(postId)
        .setData({
      "username": currentUserModel.username,
      "userId": currentUserModel.id,
      "type": "like",
      "userProfileImg": currentUserModel.photoUrl,
      "mediaUrl": mediaUrl,
      "timestamp": DateTime.now(),
      "postId": postId,
    });
  }

  void removeActivityFeedItem() {
    Firestore.instance
        .collection(Constants.COLLECTION_FEED)
        .document(ownerId)
        .collection("items")
        .document(postId)
        .delete();
  }
}

class ImagePostFromId extends StatelessWidget {
  final String id;

  const ImagePostFromId({this.id});

  getImagePost() async {
    var document = await Firestore.instance
        .collection(Constants.COLLECTION_POSTS)
        .document(id)
        .get();
    return ImagePost.fromDocument(document);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getImagePost(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                padding: const EdgeInsets.only(top: 10.0),
                child: CircularProgressIndicator());
          return snapshot.data;
        });
  }
}

void goToComments(
    {BuildContext context, String postId, String ownerId, String mediaUrl}) {
  Navigator.of(context).pushNamed(CommentPage.ROUTE, arguments: {
    'postId': postId,
    'postOwner': ownerId,
    'postMediaUrl': mediaUrl,
  });
}
