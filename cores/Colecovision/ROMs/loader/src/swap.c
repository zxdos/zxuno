////////////////////////////////////////////////////////////////////////////////
// swap.c                                                                     //
// Endianness swap functions                                                  //
//                                                                            //
// Copyright 2012-     Christian Vogelgsang, A.M. Robinson, Rok Krajnc        //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 2 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// Changelog                                                                  //
//                                                                            //
// 2012-08-02 - rok.krajnc@gmail.com                                          //
// Functions are now generic - removed assembler code. Added function-like    //
// macros (gcc specific!).                                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


#include "swap.h"

#ifdef SWAP

#ifndef SWAP_MACROS

unsigned long SwapBBBB(unsigned long i)
{
  return ((i&0x00ff0000)>>8) | ((i&0xff000000)>>24) | ((i&0x000000ff)<<24) | ((i&0x0000ff00)<<8);
}


unsigned int SwapBB(unsigned int i)
{
  return ((i&0x00ff)<<8) | ((i&0xff00)>>8);
}


unsigned long SwapWW(unsigned long i)
{
  //return ((i&0x0000ffff)<<16) | ((i&0xffff0000)>>16);
  return ((i<<16) | (i>>16));
}

#endif // SWAP_MACROS

#endif // SWAP