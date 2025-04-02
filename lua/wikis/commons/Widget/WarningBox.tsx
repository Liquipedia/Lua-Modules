import Image from '@commons/Components/Image';

export default function WarningBox({ text }: { text: string | number }) {
	return (
		<div className='show-when-logged-in navigation-not-searchable ambox-wrapper ambox wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red'>
			<table>
				<tr>
					<td className='ambox-image'>
						{<Image src='Emblem-important.svg' alt='Important' width='40' />}
					</td>
					<td className='ambox-text'>{text}</td>
				</tr>
			</table>
		</div>
	);
}
