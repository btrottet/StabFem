function [eigenvalues,eigenvector] = FreeFem_Stability(baseflow,varargin)

% Matlab/FreeFem driver for Base flow calculation (Newton iteration)
%
% usage : [eigenvalues,eigenvectors] = FreeFem_Stability(baseflow [,param1,value1] [,param2,value2] [...])
% Parameters include :
% Re : Reynolds number (specify only if it differs from the base flow, which is not usual)
% m : azimuthal wavenumer (for axisymmetric problem)
% k : transverse wavenumber (for 3D stability of 2D flow, to be implemented)
% sym : symmetry condition for a 2D problem (set to 'S' for symmetric, 'A' for antisymmetric, or 'N' if no symmetry plane is present)
% shift : for shift-invert (complex), 
% nev : number of eigenvalues
% type : 'D' for direct problem ; 'A' for ajoint problem ; 'DA' for discrete adjoint 
%
% the solver will use Arnoldi method if nev>1 and shift-invert if nev=1
% output : eigenvalues (vector of size nev) ; eigenvector(s)
%
% Version 2.0 by D. Fabre , june 2017
%

global ff ffdir ffdatadir sfdir verbosity

%%% management of optionnal parameters
    p = inputParser;
  %paramaters for axisymmetric case
   addParameter(p,'m',1,@isnumeric);
  %parameters for 2D case (to be implemented...)
   addParameter(p,'k',1,@isnumeric);
   addParameter(p,'sym','A',@ischar);
   %parameters for the eigenvalue solver
   addParameter(p,'shift',1+1i,@isnumeric);
   addParameter(p,'nev',10,@isnumeric);
   addParameter(p,'type','D',@ischar); 
   addParameter(p,'Re',baseflow.Re,@isnumeric);
   parse(p,varargin{:});
   



% run the relevant freefem script
if(strcmp(baseflow.mesh.problemtype,'AxiXR')==1)
    % Axisymmetric base flow (for sphere, whistling jet, etc..)
    % four different programs (to be unified !)
    if ((p.Results.type=='D')&&(p.Results.nev==1))
        if(verbosity>0) disp('FUNCTION FreeFem_Stability : computation of 1 eigenvalue/mode (DIRECT) with shift/invert method'); end
        [status]=mysystem(['echo ' num2str(p.Results.Re) ' ' num2str(p.Results.m) ' ' num2str(real(p.Results.shift)) ' ' num2str(imag(p.Results.shift)) ... 
           '  | ' ff ' ' ffdir 'StabAxi_ShiftInvert.edp']);
    elseif((p.Results.type=='D')&&(p.Results.nev>1)) 
        if(verbosity>0) disp(['FUNCTION FreeFem_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);end
        [status]=mysystem(['echo ' num2str(p.Results.Re) ' ' num2str(p.Results.m) ' '  num2str(real(p.Results.shift)) ' ' num2str(imag(p.Results.shift)) ' ' num2str(p.Results.nev)... 
           '  | ' ff ' ' ffdir 'StabAxi.edp']);
    elseif ((p.Results.type=='A')&&(p.Results.nev==1))
        if(verbosity>0)disp('FUNCTION FreeFem_Stability : computation of 1 eigenvalue/mode (ADJOINT) with shift/invert method');end
        [status]=mysystem(['echo ' num2str(p.Results.Re) ' ' num2str(p.Results.m) ' ' num2str(real(p.Results.shift)) ' ' num2str(imag(p.Results.shift)) ... 
           '  | ' ff ' ' ffdir 'StabAxi_ShiftInvert_ADJ.edp']);
         system('cp Eigenmode.txt Eigenmode_guess.txt');
    elseif((p.Results.type=='A')&&(p.Results.nev>1))
        if(verbosity>0)disp(['FUNCTION FreeFem_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (ADJOINT) with FF solver']);end
        [status]=mysystem(['echo ' num2str(p.Results.Re) ' ' num2str(p.Results.m) ' '  num2str(real(p.Results.shift)) ' ' num2str(imag(p.Results.shift)) ' ' num2str(p.Results.nev)... 
           '  | ' ff ' ' ffdir 'StabAxi_ADJ.edp']);
    end

elseif(strcmp(baseflow.mesh.problemtype,'2D')==1)
         % 2D flow (cylinder, etc...)
    
        if(verbosity>0)disp(['FUNCTION FreeFem_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);end
        solvercommand = ['echo '' ' num2str(p.Results.Re) ' '  num2str(real(p.Results.shift)) ' ' num2str(imag(p.Results.shift))... 
                             ' ' p.Results.sym ' ' p.Results.type ' ' num2str(p.Results.nev) ' '' | ' ff ' ' ffdir 'Stab2D.edp'];
        status = mysystem(solvercommand);
   
  

%elseif(strcmp(baseflow.mesh.problemtype,keyword)==1)
    % adapt to your case !
    
end
    

if(status~=0) 
     %result 
     error('ERROR : FreeFem stability computation aborted');
 else
   % disp(['FreeFem : FreeFem stability computed for Re = ' num2str(p.Results.Re), ' ; m = '  num2str(p.Results.m) ' shift = ' num2str(p.Results.shift) ])
  %
end



if (p.Results.type=='D')
    rawData1 = importdata(['./Eigenvalues.txt']);
else
    rawData1 = importdata(['./EigenvaluesA.txt']);
end
EVr = rawData1(:,1);
EVi = rawData1(:,2); 
eigenvalues = EVr+1i*EVi;


if(nargout==2) % handling output for the eigenmode(s)
    if(p.Results.nev==1&&p.Results.type=='D')
        eigenvector=importFFdata(baseflow.mesh,'Eigenmode.ff2m');
         disp(['      ### Stability calculation completed, eigenvalue = ',num2str(eigenvalues),' ; converged in ', num2str(eigenvector.iter),' iterations']);
    elseif(p.Results.nev==1&&p.Results.type=='A')
        eigenvector=importFFdata(baseflow.mesh,'EigenmodeA.ff2m');
         disp(['      ### Stability calculation completed (ADJOINT), eigenvalue = ',num2str(eigenvalues),' ; converged in ', num2str(eigenvector.iter),' iterations']);
    elseif(p.Results.nev>1&&p.Results.type=='D')
    for iev = 1:p.Results.nev
        eigenvector(iev)=importFFdata(baseflow.mesh,['Eigenmode' num2str(iev) '.ff2m']);
    end
    elseif(nev>1&&type=='D')
    for iev = 1:p.Results.nev
        eigenvector(iev)=importFFdata(baseflow.mesh,['EigenmodeA' num2str(iev) '.ff2m']);
    end
    else
        error('ERROR');
    end
end

end
