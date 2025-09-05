//
//  TestLeftRightCollectionViewFlowLayout.swift
//  XQMuse
//
//  Created by 无故事王国 on 2024/8/12.
//

#if canImport(UIKit)
import UIKit
class TestLeftRightCollectionViewFlowLayout: UICollectionViewFlowLayout {
				init(width:CGFloat,height:CGFloat) {
								super.init();
								//对每条边向内方向的偏移量
								let padding:CGFloat = 50.0;
								//设置cell的尺寸(宽度和高度)
								self.itemSize = CGSize(width: width-padding*2, height: height-padding);
								//设置水平滚动方向(默认是竖直方向)
								self.scrollDirection = .horizontal;
								//设置cell与cell之间的行距
								self.minimumLineSpacing = 8.0;
								//设置cell与cell之间的列距
								self.minimumInteritemSpacing = 0.0;
								//对每条边向内方向的偏移量,可以为正值（向内偏移）也可以为负值（向外偏移）
								sectionInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding);
				}

				required init?(coder aDecoder: NSCoder) {
								fatalError("init(coder:) has not been implemented")
				}

				//是否需要更新布局
				//因为每次滑动都要缩放Cell，所以这了就直接返回true
				override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
								return true
				}

				///根据当前滚动进行对每个cell进行缩放
				///用来计算出rect这个范围内所有cell的UICollectionViewLayoutAttributes，
				override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
								//首先获取 当前rect范围内的 attributes对象
								let collectionViewLayoutAttributes : [UICollectionViewLayoutAttributes] = super.layoutAttributesForElements(in: rect) ?? [];
								//计算缩放比  首先计算出整体中心点的X值 和每个cell的中心点X的值
								//用着两个x值的差值 ，计算出绝对值
								//
								//计算偏移colleciotnView中心点的X值 = X偏移量+colleciotnView的半宽
								let centerX =  (collectionView?.contentOffset.x)! + (self.collectionView?.bounds.width)!/2;
								// 可见矩阵
								let visiableRect = CGRect(x: self.collectionView!.contentOffset.x, y: self.collectionView!.contentOffset.y, width: self.collectionView!.frame.width, height: self.collectionView!.frame.height);

								//循环遍历每个attributes对象 对每个对象进行缩放
								for attr : UICollectionViewLayoutAttributes in collectionViewLayoutAttributes {
												// 不在可见区域的attributes不变化
												if !visiableRect.intersects(attr.frame) {continue}
												//计算每个对象cell中心点的X值
												let cell_centerX = attr.center.x;
												//计算两个中心点的偏移（距离=cell中心点X值-偏移的colleciotnView中心点X值）取绝对值，这个值应该是一个百位数（iPhone6S的With=375Ppt,偏离量最多375，所以缩放因子设为0.001是适合的）
												let distance = abs(cell_centerX-centerX);
												//距离越大缩放比越小，距离小 缩放比越大，缩放比最大为1，即重合
												let scale:CGFloat = 1/(1+distance * 0.001);
												//缩放(基准点为中心点)
												//CATransform3DMakeScale (CGFloat sx, CGFloat sy, CGFloat sz)
												//sx：X轴缩放，代表一个缩放比例，一般都是0-1之间的数字。
												//sy：Y轴缩放。
												//sz：整体比例变换（sx==sy）时
												//      1.sz>1，图形整体缩小;
												//      2.0<sz<1，图形整体放大;
												//      3.sz<0，发生关于原点的对称等比变换。
												attr.transform3D = CATransform3DMakeScale(1.0, scale, 1.0);
								}

								return collectionViewLayoutAttributes;
				}

				/// - Parameter proposedContentOffset: 当手指滑动的时候 最终的停止的偏移量
				/// - Returns: 返回最后位于屏幕最中央的Cell的中心点需要的偏移量
				/// 当停止滑动，确保有一Cell是位于屏幕最中央
				override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
								// 可见范围
								let lastRect = CGRect(x: proposedContentOffset.x, y: proposedContentOffset.y, width: self.collectionView!.frame.width, height: self.collectionView!.frame.height)
								//获得collectionVIew中央的X值(即显示在屏幕中央的X)
								let centerX = proposedContentOffset.x + self.collectionView!.frame.width * 0.5;
								//这个范围内所有的属性
								let attributes : [UICollectionViewLayoutAttributes] = self.layoutAttributesForElements(in: lastRect)!;
								//需要移动的距离
								var adjustOffsetX = CGFloat(MAXFLOAT);
								var tempOffsetX : CGFloat;
								for attr in attributes {
												//计算出距离中心点 最小的那个cell 和整体中心点的偏移
												tempOffsetX = attr.center.x - centerX;
												if abs(tempOffsetX) < abs(adjustOffsetX) {
																adjustOffsetX = tempOffsetX;
												}
								}
								//偏移坐标
								return CGPoint(x: (proposedContentOffset.x + adjustOffsetX), y: proposedContentOffset.y);
				}



}
#endif
