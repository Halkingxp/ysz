/*
Navicat MySQL Data Transfer

Source Server         : 127.0.0.1-本地(localhost)
Source Server Version : 50717
Source Host           : localhost:3306
Source Database       : backstage

Target Server Type    : MYSQL
Target Server Version : 50717
File Encoding         : 65001

Date: 2017-09-22 09:56:02
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `bk_account`
-- ----------------------------
DROP TABLE IF EXISTS `bk_account`;
CREATE TABLE `bk_account` (
  `bk_Account` varchar(64) NOT NULL COMMENT '后台唯一帐号',
  `gd_AccountID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '游戏唯一帐号ID',
  `bk_Password` blob NOT NULL,
  `bk_QQ` varchar(64) NOT NULL COMMENT 'QQ帐号',
  `bk_WeChat` varchar(64) NOT NULL COMMENT '微信帐号',
  `bk_Phone` bigint(15) unsigned NOT NULL DEFAULT '0' COMMENT '手机号码',
  `bk_Type` int(11) NOT NULL DEFAULT '1' COMMENT '帐号类型(0已拒绝, 1申请中, 2普通推广员, 3总代理, 11客服, 12运营专员, 13运营总监, 21制作人, 22联运, 23CEO)',
  `bk_ServerID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属服务器ID',
  PRIMARY KEY (`bk_Account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of bk_account
-- ----------------------------

-- ----------------------------
-- Table structure for `bk_log`
-- ----------------------------
DROP TABLE IF EXISTS `bk_log`;
CREATE TABLE `bk_log` (
  `bk_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `bk_Time` datetime NOT NULL COMMENT '操作时间',
  `bk_Account` varchar(128) NOT NULL DEFAULT '' COMMENT '管理员帐号',
  `bk_IP` varchar(20) NOT NULL DEFAULT '' COMMENT '操作IP',
  `bk_ServerID` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '服务器ID',
  `bk_Log` varchar(1024) NOT NULL DEFAULT '' COMMENT '日志内容',
  PRIMARY KEY (`bk_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of bk_log
-- ----------------------------

-- ----------------------------
-- Table structure for `bk_payorder`
-- ----------------------------
DROP TABLE IF EXISTS `bk_payorder`;
CREATE TABLE `bk_payorder` (
  `bk_Order` varchar(128) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '订单ID',
  `bk_AccountID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帐号ID',
  `bk_CommodityID` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '商品ID',
  `bk_Amount` int(11) NOT NULL DEFAULT '0' COMMENT '支付金额',
  `bk_PayTime` datetime NOT NULL COMMENT '支付时间',
  `bk_PayCannel` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '支付渠道(152微信, 153支付宝, 154盛付通)',
  `bk_PayIP` varchar(20) NOT NULL DEFAULT '0' COMMENT '支付时的IP',
  `bk_Results` varchar(10) NOT NULL DEFAULT 'fail' COMMENT '结果',
  PRIMARY KEY (`bk_Order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of bk_payorder
-- ----------------------------
