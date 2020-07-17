// $Id: RadioCountToLedsAppC.nc,v 1.5 2010-06-29 22:07:17 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
#include "RadioCountToLeds.h"

/**
 * Configuration for the RadioCountToLeds application. RadioCountToLeds 
 * maintains a 4Hz counter, broadcasting its value in an AM packet 
 * every time it gets updated. A RadioCountToLeds node that hears a counter 
 * displays the bottom three bits on its LEDs. This application is a useful 
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

#include<Timer.h>
#include <stdio.h>
#include<string.h>
#include "RadioCountToLedsC.h"


module BlinkToRadioC{
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface Packet;
  uses interface AMSend;
  uses interface SplitControl as AMControl;

  uses interface Receive;
}

implementation{
  uint16_t counter = 0;

  bool busy = FALSE;
  message_t pkt;        //要发送的消息

  event void Boot.booted(){     //硬件上电后调用

      call AMControl.start();    //尽管可以把这些接口直接绑定到ActiveMessageC组件,但通常还是选择绑定AMSenderC组件。
                                //不过,必须使用ActiveMessageC组件的SplitControl接口来初始化无线模块
                                //开启这个组件和它的子组件 
  }
  
  event void AMControl.startDone(error_t err){        //AMControl.start()执行完成后signal的event，也就是要执行的代码
      if(err==SUCCESS){
          call Timer0.startPeriodic(TIMER_PERIOD_MILLI); 
          dbg("Boot", "Application booted\n");                      
      }else{
          call AMControl.start();
      }
  }
 
  //貌似是用到SplitControl 这个接口必须定义该函数
  event void AMControl.stopDone(error_t err){
  }


  event void AMSend.sendDone(message_t *msg,error_t error){    //AMSend.send()执行完后signal
      if(&pkt==msg){    //msg是packet中消息,这里与本地消息比较一下，看是否是自己发的消息
          busy=FALSE;
      //dbg("BlinkToRadioC", "%hhu mote send packet,time=%s.\n",TOS_NODE_ID,call MilliTimer.getNow());
      }
  }
  event void Timer0.fired(){    //Timer0到期后signal
      counter++;  
      if(!busy){
          BlinkToRadioMsg* btrpkt=(BlinkToRadioMsg*)(call Packet.getPayload(&pkt,NULL));   //获取一个Packet地址,
                                               //搞不懂为什么要这么多参数
      btrpkt->nodeid=TOS_NODE_ID;        //填充数据    
      btrpkt->counter=counter;
      if(call AMSend.send(AM_BROADCAST_ADDR,&pkt,sizeof(BlinkToRadioMsg))==SUCCESS){   //将packet发送出去
        dbg("BlinkToRadioC", "%hhu mote send packet,time= %s.\n",TOS_NODE_ID,call MilliTimer.getNow());
        //printf("send data\r\n"); 
          busy=TRUE;
      }
      }
  }
  
  event message_t* Receive.receive(message_t *msg,void * payload,uint8_t len){        //接收到数据signal
      if(len==sizeof(BlinkToRadioMsg)){
          BlinkToRadioMsg * btrpkt=(BlinkToRadioMsg *)payload;        //数据保存在payload中
          //  call Leds.set(btrpkt->counter);
      dbg("BlinkToRadioC", "%hhu mote Receive packet,from node %hhu, counter= %hhu,time= %s.\n",
                                TOS_NODE_ID,btrpkt->nodeid,btrpkt->counter, call MilliTimer.getNow());
      }
      return msg;
  }
}


