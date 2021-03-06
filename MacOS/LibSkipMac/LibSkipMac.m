//
//  LibSkipMac.m
//  LibSkipMac
//
//  Created by Sam Lerner on 9/13/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#include <stdint.h>
#include <sys/mman.h>
#include <sys/errno.h>
#include "spresolver.h"
#include "skipman.h"
#include "asman.h"

uint64_t ps_mask = ~((1 << 12) - 1);

typedef void mk_handler_func_t(void *, int32_t);
typedef void prev_next_func_t(int64_t, int64_t, int64_t);

mk_handler_func_t *mkHandler;
prev_next_func_t *prevHandler;
prev_next_func_t *nextHandler;

uint8_t prevStructOffset = 0x50;
char handlersSet = 0;

SkipManager *skipman;
AppleScriptManager *asman;

void new_prevHandler(int64_t param1, int64_t param2, int64_t param3)
{
    printf("Previous\n");
    
    NSString *prevTID,
             *currTID;
    BOOL     shdHandle;

    shdHandle = [asman shdHandle];
    prevTID = [asman getTID];
    
    (*prevHandler)(param1, param2, param3);
    
    currTID = [asman getTID];

    if (shdHandle && [currTID compare:prevTID] != NSOrderedSame)
        [skipman pop];
}

void new_nextHandler(int64_t param1, int64_t param2, int64_t param3)
{
    printf("Next\n");
    
    NSString *tid;

    BOOL shdHandle = [asman shdHandle];
    tid = [asman getTID];
    
    if (shdHandle)
        [skipman push:tid];
    
    (*nextHandler)(param1, param2, param3);
}

void new_mkHandler(void ***appDelegate, int32_t keyCode)
{
    if (handlersSet)
        goto call_orig;
    
    printf("[+] Patching media key handlers\n");
    
    int      mprot_res;
    uint64_t prot_addr;
    size_t   prot_size;
    uint64_t fpOff;
    uint64_t *fp;
    
    fpOff = (uint64_t)(*(*appDelegate)) + prevStructOffset;
    fp = (uint64_t *)fpOff;
    
    prevHandler = (prev_next_func_t *)(*fp);
    nextHandler = (prev_next_func_t *)(*(fp+1));
    
    /*prot_addr = fpOff & ps_mask;
    prot_size = 16 + (fpOff - prot_addr);

    printf("[+] Trying to mprotect %llx - %llx\n", prot_addr, prot_addr + prot_size);
    
    if ((mprot_res = mprotect((void *)prot_addr, prot_size, PROT_WRITE)))
    {
        perror("[-] Write protect failed");
        exit(1);
    }*/
    
    *fp = (uint64_t)(&new_prevHandler);
    *(fp+1) = (uint64_t)(&new_nextHandler);
    
    /*if ((mprot_res = mprotect((void *)prot_addr, prot_size, PROT_READ | PROT_EXEC)))
    {
        perror("[-] Read | Exec protect failed");
        exit(1);
    }*/
    
    handlersSet = 1;
    
call_orig:
    (*mkHandler)(appDelegate, keyCode);
}

void patch_mk(int32_t *mk_reloc_addr, int64_t mk_reloc_pc)
{
    int      mprot_res;
    uint64_t prot_addr;
    size_t   prot_size;
    
    printf("[+] Patching mediaKey handler\n");
    
    prot_addr = (uint64_t)mk_reloc_addr & ps_mask;
    prot_size = 4 + ((uint64_t)mk_reloc_addr - prot_addr);

    printf("[+] Trying to mprotect %llx - %llx\n", prot_addr, prot_addr + prot_size);
    
    if ((mprot_res = mprotect((void *)prot_addr, prot_size, PROT_WRITE)))
    {
        perror("[-] Write protect failed");
        exit(1);
    }
    
    *mk_reloc_addr = (int32_t)((int64_t)(&new_mkHandler) - mk_reloc_pc);
    
    if ((mprot_res = mprotect((void *)prot_addr, prot_size, PROT_READ | PROT_EXEC)))
    {
        perror("[-] Read | Exec protect failed");
        exit(1);
    }
}

static void __attribute__((constructor)) initialize(void)
{
    int32_t  *mk_reloc_addr;
    int64_t  mk_reloc_pc;
    
    Class mkClass;
    SEL   mkSel;
    IMP   mkImp;
    
    printf("[+] Initializing spskip\n");
    
    mkClass = NSClassFromString(@"SPTBrowserClientMacObjCAnnex");
    mkSel = NSSelectorFromString(@"mediaKeyTap:receivedMediaKeyEvent:");
    mkImp = class_getMethodImplementation(mkClass, mkSel);
    
    mkHandler = resolve_mediaKey_subproc_addr((uint64_t)mkImp,
                                              &mk_reloc_addr,
                                              &mk_reloc_pc);
    
    printf("[+] mediaKey handler address at %p\n\t\
           reloc address at %p\n\t\
           reloc pc 0x%llx\n",
           mkHandler, mk_reloc_addr, mk_reloc_pc);
    
    patch_mk(mk_reloc_addr, mk_reloc_pc);

    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM_dd_yyyy";

    NSString * dateString = [formatter stringFromDate:[NSDate date]];
    
    skipman = [[SkipManager alloc] init:dateString];
    asman = [[AppleScriptManager alloc] init];
}

static void __attribute__((destructor)) finalize(void)
{
    [skipman close];
}
