//#ifndef TIMER_WHEELL_H_
//#define TIMER_WHEELL_H_
//#include "../Tools/TimeTools.h"
//#include "boost/function.hpp"
//#include "boost/shared_ptr.hpp"
//#include <list>
//#include <vector>
//
//typedef boost::function<void()> funcallback;
//struct TW_TIMER
//{
//	TW_TIMER(uint64 t, const funcallback& f)
//	{
//		func = f;
//		cdtime = t;
//	}
//	funcallback func;
//	uint64 cdtime;
//};
//typedef boost::shared_ptr<TW_TIMER> PTW_TIMER;
//
//typedef std::list<PTW_TIMER> TIMERS;
//typedef std::vector<TIMERS> TIMERWHEEL;
//class CTimeWheel
//{
//private:
//	CTimeWheel();
//	CTimeWheel(int n, uint64 ms);
//	~CTimeWheel();
//
//public:
//	void Init();
//	static CTimeWheel& GetInst(){ static CTimeWheel obj; return obj; }
//
//	void		UpdateWheel();
//	PTW_TIMER	RegisterTimer(uint64 ms, const funcallback& callback);
//
//
//private:
//	PTW_TIMER	_RegisterTimer(uint64 ms, PTW_TIMER ptimer);
//	uint64		_GetMaxInterval() { return N_ * Interval_;}
//	CTimeWheel* _PushWheel(CTimeWheel* pWheel);
//	void		_Tick();
//
//private:
//	uint32			N_;				// 轮数
//	uint64			Interval_;		// 时间间隔(ms)
//	uint32			CurSlot_;		// 当前位置
//	uint64			CurTime_;		// 上一次转动的时间
//	CTimeWheel*		pUpLayer_;		// 更小的时间轮
//	CTimeWheel*		pDownLayer_;	// 更大的时间轮
//	TIMERWHEEL		TimerWheel_;
//};
//#define sTimerWheel CTimeWheel::GetInst()
//
//
//#endif
