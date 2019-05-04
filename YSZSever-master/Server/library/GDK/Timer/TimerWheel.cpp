//#include "TimerWheel.h"
//
//CTimeWheel::CTimeWheel():N_(0),Interval_(0),CurSlot_(0),CurTime_(CTimeTools::GetSystemTimeToMillisecond()),pUpLayer_(NULL),pDownLayer_(NULL)
//{
//	TimerWheel_.resize(N_);
//}
//
//CTimeWheel::CTimeWheel(int n, uint64 ms):N_(n),Interval_(ms),CurSlot_(0),CurTime_(CTimeTools::GetSystemTimeToMillisecond()),pUpLayer_(NULL),pDownLayer_(NULL)
//{
//	TimerWheel_.resize(N_);
//}
//
//CTimeWheel::~CTimeWheel()
//{
//		
//}
//
//void CTimeWheel::Init()
//{
//	int n = 10;
//	uint64 ms = 100;
//	// 毫秒
//
//	sTimerWheel.TimerWheel_.resize(n);
//	sTimerWheel.N_ = n;
//	sTimerWheel.Interval_ = ms;
//
//	sTimerWheel._PushWheel(new CTimeWheel(60, 1000))->_PushWheel(new CTimeWheel(60, 60000))->_PushWheel(new CTimeWheel(24, 3600000));
//}
//
//
//void CTimeWheel::UpdateWheel()
//{
//	static uint64 ltime = CTimeTools::GetSystemTimeToMillisecond();
//	uint64 ctime = CTimeTools::GetSystemTimeToMillisecond();
//	uint64 interval = ctime - ltime;
//
//	if (ctime < ltime)
//	{
//		return;
//	}
//	
//	while (interval >= Interval_)
//	{
//		_Tick();
//		ltime	 += Interval_;
//		interval -= Interval_;
//		CurTime_ = ltime;
//	}
//}
//
//PTW_TIMER CTimeWheel::RegisterTimer(uint64 ms, const funcallback& callback)
//{
//	uint64 t = ms % Interval_;
//	if (t > (Interval_ / 2))
//	{
//		ms = ms + Interval_;
//	}
//
//	PTW_TIMER pTimer(new TW_TIMER(ms, callback));
//
//	return _RegisterTimer(ms, pTimer);
//}
//
//PTW_TIMER CTimeWheel::_RegisterTimer(uint64 ms, PTW_TIMER ptimer)
//{
//	// 如果注册的时间为0，立刻触发
//	if (ms == 0)
//	{
//		ptimer->func();
//		return NULL;
//	}
//
//	// if (ms % Interval_ != 0)
//	// {
//	// 	// 异常设定的时间不是最小时间间隔的整数倍TODO
//	// 	return NULL;
//	// }
//	
//	if (ms > _GetMaxInterval())
//	{
//		if (NULL == pDownLayer_)
//		{
//			// 异常时间超过时间轮最大值TODO
//			return NULL;
//		}
//		return pDownLayer_->_RegisterTimer(ms ,ptimer);
//	}
//
//	uint32 n = (uint32)(ms / Interval_);
//	// 不在当前轮的间隔时间内
//	if (n == 0)
//	{
//		return pUpLayer_->_RegisterTimer(ms, ptimer);
//	}
//
//	uint32 addSlot = CurSlot_ + n;
//	if (addSlot >= N_)
//	{
//		addSlot -= N_;
//	}
//
//	TIMERS &li = TimerWheel_[addSlot];
//	li.push_back(ptimer);
//
//	return ptimer;
//}
//
//
//void CTimeWheel::_Tick()
//{
//	// printf("tick %llu \r\n", CTimeTools::GetSystemTimeToMillisecond());
//	CurSlot_++;
//	if (CurSlot_ >= N_)
//	{
//		CurSlot_ = 0;
//		// 一个周期结束
//		if (pDownLayer_)
//		{
//			pDownLayer_->_Tick();
//		}
//	}
//
//	TIMERS& li = TimerWheel_[CurSlot_];
//	TIMERS::iterator it = li.begin();
//	for (; it != li.end(); it++)
//	{
//		if (pUpLayer_)
//		{
//			uint64 t = (*it)->cdtime % Interval_;
//			pUpLayer_->_RegisterTimer(t, *it);
//		}
//		else
//		{
//			(*it)->func();
//		}
//	}
//	li.clear();
//}
//
//
//CTimeWheel* CTimeWheel::_PushWheel(CTimeWheel* pwheel)
//{
//	pDownLayer_ = pwheel;
//	pwheel->pUpLayer_ = this;
//	return pwheel;
//}
