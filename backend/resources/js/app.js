import feather from 'feather-icons';
import Swal from 'sweetalert2';

window.feather = feather;
window.Swal = Swal;

document.addEventListener('DOMContentLoaded', () => {
    feather.replace();
});
