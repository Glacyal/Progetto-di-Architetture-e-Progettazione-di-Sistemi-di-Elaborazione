/**************************************************************************************
* 
* CdL Magistrale in Ingegneria Informatica
* Corso di Architetture e Programmazione dei Sistemi di Elaborazione - a.a. 2020/21
* 
* Progetto dell'algoritmo di Regressione
* in linguaggio assembly x86-32 + SSE
* 
* Fabrizio Angiulli, aprile 2019
* 
**************************************************************************************/

/*
* 
* Software necessario per l'esecuzione:
* 
*    NASM (www.nasm.us)
*    GCC (gcc.gnu.org)
* 
* entrambi sono disponibili come pacchetti software 
* installabili mediante il packaging tool del sistema 
* operativo; per esempio, su Ubuntu, mediante i comandi:
* 
*    sudo apt-get install nasm
*    sudo apt-get install gcc
* 
* potrebbe essere necessario installare le seguenti librerie:
* 
*    sudo apt-get install lib32gcc-4.8-dev (o altra versione)
*    sudo apt-get install libc6-dev-i386
* 
* Per generare il file eseguibile:
* 
* nasm -f elf32 regression32.nasm && gcc -m32 -msse -O0 -no-pie sseutils32.o regression32.o regression32c.c -o regression32c -lm && ./regression32c $pars
* 
* oppure
* 
* ./runregression32
* 
*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <libgen.h>
#include <xmmintrin.h>

#define	type		float
#define	MATRIX		type* 
#define	VECTOR		type*
//-----------------------------------------------------------------------------------------------------------
typedef enum {false,true} boolean;
//-----------------------------------------------------------------------------------------------------------
typedef struct {
    MATRIX x; //data set 
    VECTOR y; //label set
    MATRIX xast; //data set convertito x*
    int n; //numero di punti del data set
    int d; //numero di dimensioni del data set    
    int k; //dimensione del batch
    int degree; //grado del polinomio   
    type eta; //learning rate
    //STRUTTURE OUTPUT
    VECTOR theta; //vettore dei parametri
    int t; //numero di parametri, dimensione del vettore theta
    int iter; //numero di iterazioni
    int adagrad; //accelerazione adagrad
    int silent; //silenzioso
    int display; //stampa risultati
   
} params;
//-----------------------------------------------------------------------------------------------------------
/*
* 
*	Le funzioni sono state scritte assumento che le matrici siano memorizzate 
* 	mediante un array (float*), in modo da occupare un unico blocco
* 	di memoria, ma a scelta del candidato possono essere 
* 	memorizzate mediante array di array (float**).
* 
* 	In entrambi i casi il candidato dovrà inoltre scegliere se memorizzare le
* 	matrici per righe (row-major order) o per colonne (column major-order).
*
* 	L'assunzione corrente è che le matrici siano in row-major order.
* 
*/
//-----------------------------------------------------------------------------------------------------------
void* get_block(int size, int elements) { 
    return _mm_malloc(elements*size,16); 
}
//-----------------------------------------------------------------------------------------------------------
void free_block(void* p) { 
    _mm_free(p);
}
//-----------------------------------------------------------------------------------------------------------
//FUNZIONI CREAZIONE MATRICE
MATRIX alloc_matrix(int rows, int cols) {
    return (MATRIX) get_block(sizeof(type),rows*cols);
}
//-----------------------------------------------------------------------------------------------------------
void dealloc_matrix(MATRIX mat) {
    free_block(mat);
}
//-----------------------------------------------------------------------------------------------------------
/*
* 
* 	load_data
* 	=========
* 
*	Legge da file una matrice di N righe
* 	e M colonne e la memorizza in un array lineare in row-major order
* 
* 	Codifica del file:
* 	primi 4 byte: numero di righe (N) --> numero intero a 32 bit
* 	successivi 4 byte: numero di colonne (M) --> numero intero a 32 bit
* 	successivi N*M*4 byte: matrix data in row-major order --> numeri floating-point a precisione singola
* 
*****************************************************************************
*	Se lo si ritiene opportuno, è possibile cambiare la codifica in memoria
* 	della matrice. 
*****************************************************************************
* 
*/
MATRIX load_data(char* filename, int *n, int *k) {
    FILE* fp;
    int rows, cols, status, i;
    
    fp = fopen(filename, "rb");
    
    if (fp == NULL){
        printf("'%s': bad data file name!\n", filename);
        exit(0);
    }
    
    //SERVE PER LEGGERE SU UN FILE UN BLOCCO DI DATI DI QUALSIASI TIPO
    //fread(DOVE METTERE IL NUMERO LETTO, DIMENSIONE DATO LETTO, N ELEMENTI, DA DOVE LEGGERLI)
    status = fread(&cols, sizeof(int), 1, fp);  
    status = fread(&rows, sizeof(int), 1, fp);
    

    //inserisce tutti gli elementi (righe*colonne)
    MATRIX data = alloc_matrix(rows,cols);
    status = fread(data, sizeof(type), rows*cols, fp);
    fclose(fp);
    
    //numero punti nel dataset n
    *n = rows;
    //numero dimensione d
    *k = cols;
    
    return data;
}
//-----------------------------------------------------------------------------------------------------------
/*
* 	save_data
* 	=========
* 
*	Salva su file un array lineare in row-major order
*	come matrice di N righe e M colonne
* 
* 	Codifica del file:
* 	primi 4 byte: numero di righe (N) --> numero intero a 32 bit
* 	successivi 4 byte: numero di colonne (M) --> numero intero a 32 bit
* 	successivi N*M*4 byte: matrix data in row-major order --> numeri interi o floating-point a precisione singola
*/
void save_data(char* filename, void* X, int n, int k) {
    FILE* fp;
    int i;
    fp = fopen(filename, "wb");
    if(X != NULL){
        fwrite(&k, 4, 1, fp);
        fwrite(&n, 4, 1, fp);
        for (i = 0; i < n; i++) {
            fwrite(X, sizeof(type), k, fp);
            //printf("%i %i\n", ((int*)X)[0], ((int*)X)[1]);
            X += sizeof(type)*k;
        }
    }
    fclose(fp);
}
//-----------------------------------------------------------------------------------------------------------
//METODO CALCOLO DIMENSIONE X ESTESTO (X*)
//DIMXAST----------------------------------------------------------------------------------------------------
//extern long dimxast(int grado,int dim);
long dimxast(int grado,int dim){
    	int i,j;
        long num;
		long res = dim+1;
		long den = 1;

		for(i=1; i<=dim-1; i++) {
		     den*=i;
	    }
		
		for (j = 2; j <= grado; j++) {
			num = 1;
			for(i = dim+j-1; i>j; i--) {
				num*= i;
			}
			res+= num/den;
		}
        return res;
}
//-----------------------------------------------------------------------------------------------------------
//INIZIALIZZAGRADOUNO----------------------------------------------------------------------------------------
extern int inizializzaGradoUnoUnroll(type* pxast,int rig,int dim,type* px,int indiceXast,int t);
extern int inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast);
/*void inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast){
    int i;
    int offset;
    offset=rig*dim;
   
    for(i=0;i<dim;i++){
        
        pxast[indiceXast]=px[offset];
        offset++;
        indiceXast++;

    }
}*/
//-----------------------------------------------------------------------------------------------------------
//RIPRISTINAVETZERO------------------------------------------------------------------------------------------
extern void ripristinaVetZero(int v[], int scarto,int grado);
/*void ripristinaVetZero(int v[], int gCorr,int grado){
	int i;
  
    for(i = grado-gCorr;i< grado;i++){
        v[i] = 0;
    }

}*/
///----------------------------------------------------------------------------------------------------------
//TUTTIX-----------------------------------------------------------------------------------------------------
extern void tuttiX(int v[], int x, int j,int grado);
/*void tuttiX(int v[], int x, int j,int grado) {
	int i;
    
    for(i = j; i < grado;i++){
        v[i] = x;
    }
    
}*/
//-------------------------------------------------------------------------------------------------------------
//PRODUTTORIA--------------------------------------------------------------------------------------------------
extern void calcoloXastGradoMaggioreDueUnroll(type* x,int dim,int rig,int v[],int scarto,type* xast, int indiceXast,int grado,int t);
extern void calcoloXastGradoMaggioreDue(type* x,int dim,int rig,int v[],int scarto,type* xast, int indiceXast,int grado);
/*void calcoloXastGradoMaggioreDue(type* x,int dim,int rig,int v[],int scarto,type* xast, int indiceXast,int grado){
    int i;
    int offset;
    int indice;

    offset=rig*dim;
    indice=((offset)+v[scarto]);
    xast[indiceXast]=x[indice];

    for(i=scarto+1;i<grado;i++){

        indice=((offset)+v[i]);
        xast[indiceXast]*=x[indice];
        
    }
}*/
//-------------------------------------------------------------------------------------------------------------

void convert(int rig,type* pxast,type* px,int grado,int dim,int degree,int t){

    int i, gCorr, indMaxGrado;
    int v[degree];
    int val=dim-1;
    int indiceXast=rig*t;

    pxast[indiceXast]=1.0;
    indiceXast++;

    inizializzaGradoUno(pxast,rig,dim,px,indiceXast);
    indiceXast+=dim;
    
    for(gCorr = 2; gCorr <= grado;gCorr++){
        
        indMaxGrado=grado-gCorr;
        ripristinaVetZero(v,indMaxGrado,grado);
        
       
        while(v[indMaxGrado]!= val){
            calcoloXastGradoMaggioreDue(px,dim,rig,v,indMaxGrado,pxast,indiceXast,grado);         
            indiceXast++;

            if(v[grado-1]==val){
                
                for(i= grado-2;true;i--){
                    if(v[i]<val){
                        v[i]++;
                        tuttiX(v,v[i],i,grado);
                        break;
                    }
                }
                if(v[indMaxGrado] == val){ 
                    calcoloXastGradoMaggioreDue(px,dim,rig,v,indMaxGrado,pxast,indiceXast,grado);
                    indiceXast++;
                    break;
                }
            }
            else v[grado-1]++;
        }                      
    }
}

void convertUnroll(int rig,type* pxast,type* px,int grado,int dim,int degree,int t){

    int i, gCorr, indMaxGrado;
    int v[degree];
    int val=dim-1;
    int indiceXast=rig*t;

    pxast[indiceXast]=1.0;
    indiceXast++;

    pxast[(rig+1)*t]=1.0;    pxast[(rig+2)*t]=1.0;    pxast[(rig+3)*t]=1.0;
    pxast[(rig+4)*t]=1.0;    pxast[(rig+5)*t]=1.0;    pxast[(rig+6)*t]=1.0;
    pxast[(rig+7)*t]=1.0;

    inizializzaGradoUnoUnroll(pxast,rig,dim,px,indiceXast,t);
    indiceXast+=dim;

    for(gCorr = 2; gCorr <= grado;gCorr++){
        
        indMaxGrado=grado-gCorr;
        ripristinaVetZero(v,indMaxGrado,grado);
       
        while(v[indMaxGrado]!= val){
            calcoloXastGradoMaggioreDueUnroll(px,dim,rig,v,indMaxGrado,pxast,indiceXast,grado,t);
            indiceXast++;

            if(v[grado-1]==val){          
                for(i= grado-2;true;i--){
                    if(v[i]<val){
                        v[i]++;
                        tuttiX(v,v[i],i,grado);
                        break;
                    }
                }
                if(v[indMaxGrado] == val){
                    calcoloXastGradoMaggioreDueUnroll(px,dim,rig,v,indMaxGrado,pxast,indiceXast,grado,t);               
                    indiceXast++;                  
                    break;
                }
            }
            else v[grado-1]++;
        }               
    }
}

//--------------------------------------------------------------------------------------------------
//CONVERT_DATA--------------------------------------------------------------------------------------
void convert_data(params* input){
    int i,j; 
    int dim  = input->d;;
    int grado= input->degree;;
    type* px = input->x;;
    type* pxast;
    int UNROLL=8;
    int restoMultiplo=(input->n/UNROLL)*UNROLL;
    
    //CALCOLO DIM DI X*
    input->t=dimxast(grado,dim);
    input->xast=_mm_malloc((input->t*input->n)*sizeof(type),16);
    pxast=input->xast;
    


#pragma omp parallel for
for(i=0;i<restoMultiplo;i=i+UNROLL){
    convertUnroll(i,pxast,px,grado,dim,input->degree,input->t);     
} 

for(j=restoMultiplo;j<input->n;j++){
          convert(j,pxast,px,grado,dim,input->degree,input->t);
}

}

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
//PRODOTTOVETTXETA----------------------------------------------------------------------------------
type prodottoErroreEta(type* xast,type* pTheta,int dimTheta,int offset,type eta,type y){
    type ris;
    int i;
    int off;
  
    ris=0;

    for(i=0;i<dimTheta;i++){
        off=offset+i;
        ris+=xast[off]*pTheta[i];
    }
     
    ris=(ris-y)*eta;

    return ris;
}
//--------------------------------------------------------------------------------------------------------
//SGDNORMAL-----------------------------------------------------------------------------------------------
void sgdNormal(params* input){

    int i;
    int dimTheta;
    int it;
    int j;
    int offset;
    type risProd;
    type* pxast=input->xast;
    type* pTheta;

    it=0;
    dimTheta=input->t;

    input->theta=_mm_malloc(dimTheta*sizeof(type),16);
    pTheta=input->theta;
    
    //INIZIALIZZAZIONE
    for(i=0;i<dimTheta;i++){
        pTheta[i]=0;
    }

    while(it<input->iter){
        offset=0;
        for(i=0;i<input->n;i++){

            risProd=prodottoErroreEta(pxast,pTheta,dimTheta,offset,input->eta,input->y[i]);
            //Calcolo Theta
            for(j=0;j<dimTheta;j++){ 
                pTheta[j]=(pTheta[j])-(risProd*pxast[j+offset]);
            }
                    
            offset+=dimTheta;            
        }
        it++;
    }

}
//--------------------------------------------------------------------------------------------------------
//PRODOTTOERRORExETAxXAST---------------------------------------------------------------------------------
extern void prodottoErrorexEtaxXast(type* xast,type* pTheta,type* risultato,int dimTheta,type y,int offset);
/*void prodottoErrorexEtaxXast(type* xast,type* pTheta,type* risultato,int dimTheta,type y,int offset){
    type ris=0;
    int i;
    
    //CALCOLO <THETA,X*>
    for(i=0;i<dimTheta;i++){
        ris+=pTheta[i]*xast[offset+i];
    }

    //CALCOLO <THETA,X*>-YI
    ris=ris-y;

    //CALCOLO <THETA,X*>-YI * X*
    for(i=0;i<dimTheta;i++){
        risultato[i]+=xast[offset+i]*ris;
    }
         
}*/
//INIZIALIZZAVETAZERO-------------------------------------------------------------------------------------
extern void inizializzaVetAZero(type* pTheta,int dimTheta);
/*void inizializzaVetAZero(type* pTheta,int dimTheta){
    int i;
    for(i=0;i<dimTheta;i++){
        pTheta[i]=0;
    }
}*/
//CALCOLOTHETA---------------------------------------------------------------------------------------------
extern void calcoloPTheta(type* pTheta,type* risultato,type div,int dimTheta);
/*void calcoloPTheta(type* pTheta,type* risultato,type div,int dimTheta){
    int i;
    for(i=0;i<dimTheta;i++){                         
      pTheta[i]=(pTheta[i])-(risultato[i]*div);   
      risultato[i] = 0;                     
    }
}*/
//--------------------------------------------------------------------------------------------------------
//SGDBATCH------------------------------------------------------------------------------------------------
void sgdBatch(params* input){
  
    int i, k, j, it;
    int batch=input->k;
    int numRighe, dimTheta;
    int finalblock, resto;
    type* pxast=input->xast;
    type* pTheta;
    type div;

    numRighe=input->n;
    dimTheta=input->t;
    type* risultato=_mm_malloc(dimTheta*sizeof(type),16);
    input->theta=_mm_malloc(dimTheta*sizeof(type),16);
    pTheta=input->theta;

    
    //INIZIALIZZAZIONE
    inizializzaVetAZero(pTheta,dimTheta);
    inizializzaVetAZero(risultato,dimTheta);

    // numero di batch gestiti 
    div=(input->eta)/batch; 
    finalblock=(numRighe/batch)*batch; //NUMERO DI RIGHE DA GESTIRE MULTIPLE DEL BATCH
    resto=numRighe-finalblock;         //R == 0 BATCH MULTIPLO DELLE RIGHE vs R != 0 BATCH NON MULTIPLO DELLE RIGHE
    it=0;
//RESTO==0-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
        if(resto==0){
            
            while(it<input->iter){  
               
                for(i=0;i<finalblock;i=i+batch){
                    for(j=i;j<(i+batch);j++){
                     int offset=dimTheta*j;  
                     prodottoErrorexEtaxXast(pxast,pTheta,risultato,dimTheta,input->y[j],offset);                               
                    }
             
                    calcoloPTheta(pTheta,risultato,div,dimTheta);
                    
                }      
             it++;
            }//WHILE
        }//IF
//RESTO!=0-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
        else{
            type div1=(input->eta)/resto;
            while(it<input->iter){ 
                for(i=0;i<finalblock;i=i+batch){

                  for(j=i;j<(i+batch);j++){
                     int offset=dimTheta*j;  
                     prodottoErrorexEtaxXast(pxast,pTheta,risultato,dimTheta,input->y[j],offset);                               
                  }
             
                  calcoloPTheta(pTheta,risultato,div,dimTheta);
                }
                    //ULTIMO CASO---------------------------------------------------------------------------- 

                    for(j=finalblock;j<(i+resto);j++){
                        int offset=dimTheta*j;  
                        prodottoErrorexEtaxXast(pxast,pTheta,risultato,dimTheta,input->y[j],offset);                               
                    }

                    calcoloPTheta(pTheta,risultato,div1,dimTheta);
                    //---------------------------------------------------------------------------------------                               
            it++;
        }//WHILE
      }//ELSE
//-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
}
//------------------------------------------------------------------------------------------------------
extern void calcoloPThetaAdagrad(type* pTheta,type* risultato,type batch,int dimTheta);
/*void calcoloPThetaAdagrad(type* pTheta,type* risultato,type batch,int dimTheta){
    int j;
        for(j=0;j<dimTheta;j++){          
                pTheta[j]=(pTheta[j])-(risultato[j]/batch); 
                risultato[j] = 0;         
        } 
}*/
//--------------------------------------------------------------------------------------------------
//CALCOLOPARZIALE-----------------------------------------------------------------------------------
extern void calcoloParziale(type* pxast,type* pTheta,type* Gj,int dimTheta,type y,int offset,int offsetPxast,type eta,type eps,type* risultato);
/*void calcoloParziale(type* pxast,type* pTheta,type* Gj,int dimTheta,type y,int offset,int offsetPxast,type eta,type eps,type* risultato){
    type ris, gj, radice, sqrtrad;
    int i, off;
    ris=0;
 
    //CALCOLO <THETA,X*>
    for(i=0;i<dimTheta;i++){
        ris+=pTheta[i]*pxast[offsetPxast+i];        
    }
    //CALCOLO <THETA,X*>-YI
    ris=ris-y;
    
    //CALCOLO <THETA,X*>-YI * X*
    for(i=0;i<dimTheta;i++){
        off=offset+i;
//--------------------------------------------------------------------------------------------------
        gj = pxast[offsetPxast+i]*ris;  //void calcologPiccoloJ
//--------------------------------------------------------------------------------------------------
	    Gj[off] =Gj[off] + gj*gj;	    //void calcologGrandeJ
//--------------------------------------------------------------------------------------------------
        gj = gj*eta;					//void calcoloSommatoria
        sqrtrad = Gj[off]+eps;
        radice = sqrt(sqrtrad);
        
        risultato[i]+=(gj/radice);
//--------------------------------------------------------------------------------------------------

    }      
}*/
//--------------------------------------------------------------------------------------------------
//SDGADAGRAD----------------------------------------------------------------------------------------
void sgdAdagrad(params* input){
    int i,j,it;
    type* pxast=input->xast;
    type* pTheta;
    int batch=input->k;
    int dimTheta=input->t;
    
    type eps=1E-8;

    input->theta=_mm_malloc(dimTheta*sizeof(type),16);
    pTheta=input->theta;
    
    type* Gj=_mm_malloc((dimTheta*batch)*sizeof(type),16);
    type* risultato=_mm_malloc(dimTheta*sizeof(type),16);

    //INIZIALIZZAZIONE
    inizializzaVetAZero(Gj,dimTheta*batch);
    inizializzaVetAZero(pTheta,dimTheta);
    inizializzaVetAZero(risultato,dimTheta);

    int finalblock=(input->n/batch)*batch; //NUMERO DI RIGHE DA GESTIRE
    int resto=input->n-finalblock;         //R == 0 BATCH MULTIPLO DELLE RIGHE vs R != 0 BATCH NON MULTIPLO DELLE RIGHE

    it=0;
    if(resto==0){
        while(it<input->iter){            
        for(i=0;i<finalblock;i=i+batch){                          
            //FOR CREAZIONI gj e Gj
            //-------------------------------------------------------------------------------------------------------
            for(j=i;j<(i+batch);j++){
             int offsetPxast=dimTheta*j;
             int offset=dimTheta*(j%batch); 
            
             calcoloParziale(pxast,pTheta,Gj,dimTheta,input->y[j],offset,offsetPxast,input->eta,eps,risultato);                   
             }
            //-------------------------------------------------------------------------------------------------------
                          
            calcoloPThetaAdagrad(pTheta,risultato,batch,dimTheta);
        }
        it++;
        }//WHILE
}//IF
    else{
     while(it<input->iter){         
        for(i=0;i<finalblock;i=i+batch){                            
            //FOR CREAZIONI gj e Gj
            //-------------------------------------------------------------------------------------------------------
            for(j=i;j<(i+batch);j++){
             int offsetPxast=dimTheta*j;
             int offset=dimTheta*(j%batch);

             calcoloParziale(pxast,pTheta,Gj,dimTheta,input->y[j],offset,offsetPxast,input->eta,eps,risultato);    
             }
            //-------------------------------------------------------------------------------------------------------
            //FOR CREAZIONE THETA            

            calcoloPThetaAdagrad(pTheta,risultato,batch,dimTheta);
        }//FINE FOR FINO A FINALBLOCK                      
            //FOR CREAZIONI gj e Gj
            //-------------------------------------------------------------------------------------------------------
         //   printf("%d \n",finalblock);
            for(j=finalblock;j<(finalblock+resto);j++){
             int offsetPxast=dimTheta*j;
             int offset=dimTheta*(j%resto); 
             calcoloParziale(pxast,pTheta,Gj,dimTheta,input->y[j],offset,offsetPxast,input->eta,eps,risultato);    
             }
            //-------------------------------------------------------------------------------------------------------
            //FOR CREAZIONE THETA            
            calcoloPThetaAdagrad(pTheta,risultato,resto,dimTheta);
         
        it++;
        }
    }//ELSE
   
}
//--------------------------------------------------------------------------------------------------
//ASD-----------------------------------------------------------------------------------------------
void sgd(params* input){
 /*sgdNormal(input);*/    
   if(!input->adagrad)
    sgdBatch(input);
   else
    sgdAdagrad(input);   
}
//--------------------------------------------------------------------------------------------------
//ErroreQuadraticoMedio-----------------------------------------------------------------------------
void ErroreQuadraticoMedio(params* input){
    int i,j;
    int offset;
    type prodottoscalare;
    type errore;
    type ris=0;
    for(i=0;i<input->n;i++){
        prodottoscalare=0;

        offset=input->t*i;
        for(j=0;j<input->t;j++){
         prodottoscalare += (input->xast[offset+j])*(input->theta[j]);
        }

        errore = (input->y[i]-prodottoscalare);
        ris += errore*errore;
    }
    ris/=input->n;
    printf("\n");
    printf("ErroreQuadraticoMedio = %f \n",ris); 

    if(false){//METTERE A TRUE PER VEDERE Y
    float ris=0;
    float erroremedioy=0;
    int off=0;
    printf("\n");
    for(i=0;i<input->n;i++){
        for(j=0;j<input->t;j++){
         ris+=input->xast[off+j]*input->theta[j];
        }
        off+=input->t;
        if(ris-input->y[i]<0)   erroremedioy +=(ris-input->y[i]*-1);
        else                    erroremedioy +=ris-input->y[i];
        if(ris-input->y[i]<0)
        printf("[%.2f]",ris-input->y[i]);
        else 
        printf("[+%.2f]",ris-input->y[i]);
        if((i+1)%25==0)printf("\n");
        ris=0;
   
    }
    printf("\nERROREMEDIOY = [%.4f] \n",erroremedioy/input->n); 
    }
}




//--------------------------------------------------------------------------------------------------
//MAIN----------------------------------------------------------------------------------------------
int main(int argc, char** argv) {

    int f;
    int a;

    char fname[256];
    char* dsname;
    char* filename;
    int i, j, k;
    clock_t t;
    float time;
    int yd = 1;

   
    //
    // Imposta i valori di default dei parametri
    //

    params* input = malloc(sizeof(params));
    
    
    input->x = NULL;
    input->y = NULL;
    input->xast = NULL;
    input->n = 0;
    input->d = 0;
    input->k = -1;
    input->degree = -1;
    input->eta = -1;
    input->iter = -1;
    input->adagrad = 0;
    input->theta = NULL;
    input->t = 0;
    input->silent = 0;
    input->display = 0;


    //
    // Visualizza la sintassi del passaggio dei parametri da riga comandi
    //



    if(argc <= 1){
        printf("%s D -batch <k> -degree <deg> -eta <eta> -iter <it> [-adagrad]\n", argv[0]);
        printf("\nParameters:\n");
        printf("\tD: il nome del file, estensione .data per i dati x, estensione .labels per le etichette y\n");
        printf("\t-batch <k>: il numero di campini nel batch\n");
        printf("\t-degree <deg>: il grado del polinomio\n");
        printf("\t-eta <eta>: il learning rate\n");
        printf("\t-iter <it>: il numero di iterazioni\n");
        printf("\t-adagrad: l'acceleratore AdaGrad\n");
        exit(0);
    }
    
    //
    // Legge i valori dei parametri da riga comandi
    //
    
    int par = 1;
    while (par < argc) {
        if (par == 1) {
            filename = argv[par];
            par++;
        } else if (strcmp(argv[par],"-s") == 0) {
            input->silent = 1;
            par++;
        } else if (strcmp(argv[par],"-d") == 0) {
            input->display = 1;
            par++;
        } else if (strcmp(argv[par],"-batch") == 0) {
            par++;
            if (par >= argc) {
                printf("Missing batch dimension value!\n");
                exit(1);
            }
            input->k = atoi(argv[par]);
            par++;
        } else if (strcmp(argv[par],"-degree") == 0) {
            par++;
            if (par >= argc) {
                printf("Missing degree value!\n");
                exit(1);
            }
            input->degree = atoi(argv[par]);
            par++;
        } else if (strcmp(argv[par],"-eta") == 0) {
            par++;
            if (par >= argc) {
                printf("Missing eta value!\n");
                exit(1);
            }
            input->eta = atof(argv[par]);
            par++;
        } else if (strcmp(argv[par],"-iter") == 0) {
            par++;
            if (par >= argc) {
                printf("Missing iter value!\n");
                exit(1);
            }
            input->iter = atoi(argv[par]);
            par++;
        } else if (strcmp(argv[par],"-adagrad") == 0) {
            input->adagrad = 1;
            par++;
        } else{
            printf("WARNING: unrecognized parameter '%s'!\n",argv[par]);
            par++;
        }
    }
    
    //
    // Legge i dati e verifica la correttezza dei parametri
    //
    
    if(filename == NULL || strlen(filename) == 0){
        printf("Missing input file name!\n");
        exit(1);
    }

    dsname = basename(strdup(filename));
    sprintf(fname, "%s.data", filename);
    input->x = load_data(fname, &input->n, &input->d);
    sprintf(fname, "%s.labels", filename);
    input->y = load_data(fname, &input->n, &yd);

    if(input->k < 0){
        printf("Invalid value of batch dimension parameter!\n");
        exit(1);
    }
    
    if(input->degree < 0){
        printf("Invalid value of degree parameter!\n");
        exit(1);
    }
    
    if(input->eta < 0){
        printf("Invalid value of eta parameter!\n");
        exit(1);
    }
    
    if(input->iter < 0){
        printf("Invalid value of iter parameter!\n");
        exit(1);
    }
    
    //
    // Visualizza il valore dei parametri
    //
    
    if(!input->silent){
        printf("Input data name: '%s.data'\n", filename);
        printf("Input label name: '%s.labels'\n", filename);
        printf("Data set size [n]: %d\n", input->n);
        printf("Number of dimensions [d]: %d\n", input->d);
        printf("Batch dimension: %d\n", input->k);
        printf("Degree: %d\n", input->degree);
        printf("Eta: %f\n", input->eta);
        printf("Iter: %d\n", input->iter);
        if(input->display)
            printf("display enabled\n");
        else
            printf("display disabled\n");
        if(input->adagrad)
            printf("Adagrad enabled\n");
        else
            printf("Adagrad disabled\n");        
    }
    
   

    //
    // Conversione Dati
    //

    t = clock();
    if(input->degree==0){
        int i;
        input->xast=malloc((input->n)*sizeof(type));
        for(i=0;i<input->n;i++){  
          input->xast[i]=1.0;
          }
        input->t=1;
    }

    else 
       convert_data(input);
    t = clock() - t;
    time = ((float)t)/CLOCKS_PER_SEC;
    sprintf(fname, "%s.xast", dsname);
 
       
    if(!input->silent)
        printf("Conversion time = %f secs\n", time);
    else
        printf("%.3f\n", time);
    
    //
    // Regressione
    //

    
    t = clock();
    sgd(input);
    t = clock() - t;
    time = ((float)t)/CLOCKS_PER_SEC;
    
    if(!input->silent)
        printf("Regression time = %f secs\n", time);
    else
        printf("%.3f\n", time);
       

    //
    // Salva il risultato di theta
    //
    
    if(!input->adagrad)
	    sprintf(fname, "%s.theta.sgdomp", dsname);
    else
	    sprintf(fname, "%s.theta.adagradomp", dsname);

    save_data(fname, input->theta, input->t, 1);

    if(input->display){
        printf("theta: [");
        for(i=0; i<input->t-1; i++)
            printf("%f,", input->theta[i]);
        printf("%f]\n", input->theta[i]);
        ErroreQuadraticoMedio(input);
    }
    
    if(!input->silent)
        printf("\nDone.\n");

   
    return 0;

}
//--------------------------------------------------------------------------------------------------
